#!/usr/bin/env python3
"""
Model manager for judge command
Handles model discovery, validation, downloading, and path resolution
"""

import os
import sys
import json
import platform
import psutil
import requests
from pathlib import Path
from typing import Dict, List, Optional, Tuple, Any
from urllib.parse import urlparse, quote
import hashlib
import time
from datetime import datetime, timedelta
import yaml


class ModelManager:
    """Manages LLM models for the judge command"""
    
    HUGGINGFACE_API = "https://huggingface.co/api"
    CACHE_DIR = Path.home() / ".agentyard" / ".cache"
    CACHE_EXPIRY = timedelta(days=7)
    
    # Recommended quantizations based on system specs
    QUANT_RECOMMENDATIONS = {
        "high": ["Q8_0", "Q6_K", "Q5_K_M"],
        "medium": ["Q5_K_M", "Q4_K_M", "Q4_0"],
        "low": ["Q4_K_M", "Q3_K_M", "Q2_K"]
    }
    
    def __init__(self, config_path: Optional[str] = None):
        self.config_path = Path(config_path) if config_path else None
        self.config = self._load_config() if config_path else {}
        self.cache_dir = self.CACHE_DIR / "model_info"
        self.cache_dir.mkdir(parents=True, exist_ok=True)
    
    def _load_config(self) -> Dict[str, Any]:
        """Load configuration from YAML file"""
        if not self.config_path or not self.config_path.exists():
            return {}
        
        try:
            with open(self.config_path, 'r') as f:
                return yaml.safe_load(f) or {}
        except Exception as e:
            print(f"Warning: Failed to load config: {e}", file=sys.stderr)
            return {}
    
    def get_model_path(self, model_name: str) -> Path:
        """
        Resolve model path using hierarchy:
        1. Per-model path in config
        2. Environment variable AGENTYARD_MODELS_PATH
        3. Config file models_dir setting
        4. Default: ~/.agentyard/models/
        """
        # Check for per-model path in config
        if self.config:
            model_config = self.config.get('models', {}).get(model_name, {})
            if 'path' in model_config:
                return Path(os.path.expanduser(model_config['path']))
        
        # Check environment variable
        env_path = os.environ.get('AGENTYARD_MODELS_PATH')
        if env_path:
            return Path(os.path.expanduser(env_path)) / f"{model_name}.gguf"
        
        # Check config file models_dir
        if self.config and 'models_dir' in self.config:
            models_dir = Path(os.path.expanduser(self.config['models_dir']))
            return models_dir / f"{model_name}.gguf"
        
        # Default path
        return Path.home() / ".agentyard" / "models" / f"{model_name}.gguf"
    
    def _get_system_specs(self) -> str:
        """Determine system capability level based on RAM and GPU"""
        total_ram_gb = psutil.virtual_memory().total / (1024 ** 3)
        
        # Check for GPU support
        has_gpu = False
        if platform.system() == "Darwin":
            # macOS with Metal support
            has_gpu = True
        else:
            # Check for CUDA on Linux/Windows
            try:
                import subprocess
                result = subprocess.run(['nvidia-smi'], capture_output=True, text=True)
                has_gpu = result.returncode == 0
            except:
                has_gpu = False
        
        # Determine capability level
        if has_gpu and total_ram_gb >= 32:
            return "high"
        elif (has_gpu and total_ram_gb >= 16) or total_ram_gb >= 24:
            return "medium"
        else:
            return "low"
    
    def _cache_key(self, model_id: str) -> str:
        """Generate cache key for a model ID"""
        return hashlib.md5(model_id.encode()).hexdigest()
    
    def _get_cached_model_info(self, model_id: str) -> Optional[Dict]:
        """Get model info from cache if not expired"""
        cache_file = self.cache_dir / f"{self._cache_key(model_id)}.json"
        
        if not cache_file.exists():
            return None
        
        try:
            with open(cache_file, 'r') as f:
                cached = json.load(f)
            
            # Check expiry
            cached_time = datetime.fromisoformat(cached['timestamp'])
            if datetime.now() - cached_time > self.CACHE_EXPIRY:
                cache_file.unlink()
                return None
            
            return cached['data']
        except:
            return None
    
    def _save_model_info_to_cache(self, model_id: str, data: Dict):
        """Save model info to cache"""
        cache_file = self.cache_dir / f"{self._cache_key(model_id)}.json"
        
        try:
            with open(cache_file, 'w') as f:
                json.dump({
                    'timestamp': datetime.now().isoformat(),
                    'data': data
                }, f)
        except:
            pass
    
    def query_huggingface_model(self, model_id: str) -> Optional[Dict]:
        """Query HuggingFace for model information"""
        # Check cache first
        cached = self._get_cached_model_info(model_id)
        if cached:
            return cached
        
        # Query HuggingFace API
        try:
            # Try direct model API first
            response = requests.get(
                f"{self.HUGGINGFACE_API}/models/{model_id}",
                timeout=10
            )
            
            if response.status_code == 200:
                data = response.json()
                self._save_model_info_to_cache(model_id, data)
                return data
            
            # If not found, search for GGUF variants
            search_query = model_id.replace('/', ' ') + " gguf"
            response = requests.get(
                f"{self.HUGGINGFACE_API}/models",
                params={
                    "search": search_query,
                    "filter": "gguf",
                    "limit": 10
                },
                timeout=10
            )
            
            if response.status_code == 200:
                results = response.json()
                if results:
                    # Return the first result
                    data = results[0]
                    self._save_model_info_to_cache(model_id, data)
                    return data
        
        except Exception as e:
            print(f"Warning: Failed to query HuggingFace: {e}", file=sys.stderr)
        
        return None
    
    def find_gguf_files(self, model_info: Dict) -> List[Dict]:
        """Find GGUF files for a model"""
        model_id = model_info.get('id', '')
        
        try:
            # Get the list of files
            response = requests.get(
                f"{self.HUGGINGFACE_API}/models/{model_id}/tree/main",
                timeout=10
            )
            
            if response.status_code != 200:
                return []
            
            files = response.json()
            
            # Filter for GGUF files
            gguf_files = []
            for file in files:
                if file['path'].endswith('.gguf'):
                    # Extract quantization from filename
                    filename = file['path'].split('/')[-1]
                    quant = None
                    for q in ["Q8_0", "Q6_K", "Q5_K_M", "Q5_K_S", "Q4_K_M", "Q4_K_S", "Q4_0", "Q3_K_M", "Q3_K_L", "Q2_K"]:
                        if q in filename.upper():
                            quant = q
                            break
                    
                    gguf_files.append({
                        'filename': filename,
                        'path': file['path'],
                        'size': file.get('size', 0),
                        'quantization': quant,
                        'url': f"https://huggingface.co/{model_id}/resolve/main/{file['path']}"
                    })
            
            return gguf_files
        
        except Exception as e:
            print(f"Warning: Failed to list model files: {e}", file=sys.stderr)
            return []
    
    def recommend_quantization(self, gguf_files: List[Dict]) -> Optional[Dict]:
        """Recommend best quantization based on system specs"""
        if not gguf_files:
            return None
        
        system_level = self._get_system_specs()
        recommended_quants = self.QUANT_RECOMMENDATIONS[system_level]
        
        # Find the best match
        for quant in recommended_quants:
            for file in gguf_files:
                if file.get('quantization') == quant:
                    return file
        
        # If no match, return the first file
        return gguf_files[0]
    
    def download_model(self, url: str, dest_path: Path, show_progress: bool = True) -> bool:
        """Download a model file with progress indicator"""
        try:
            # Ensure destination directory exists
            dest_path.parent.mkdir(parents=True, exist_ok=True)
            
            # Download with streaming
            response = requests.get(url, stream=True, timeout=30)
            response.raise_for_status()
            
            total_size = int(response.headers.get('content-length', 0))
            block_size = 8192
            downloaded = 0
            
            # Temporary file
            temp_path = dest_path.with_suffix('.tmp')
            
            with open(temp_path, 'wb') as f:
                for chunk in response.iter_content(block_size):
                    if chunk:
                        f.write(chunk)
                        downloaded += len(chunk)
                        
                        if show_progress and total_size > 0:
                            percent = (downloaded / total_size) * 100
                            mb_downloaded = downloaded / (1024 * 1024)
                            mb_total = total_size / (1024 * 1024)
                            
                            # Simple progress bar
                            bar_length = 40
                            filled = int(bar_length * downloaded / total_size)
                            bar = '█' * filled + '░' * (bar_length - filled)
                            
                            print(f"\r📥 Downloading: [{bar}] {percent:.1f}% ({mb_downloaded:.1f}/{mb_total:.1f} MB)", 
                                  end='', file=sys.stderr)
            
            # Move to final location
            temp_path.rename(dest_path)
            
            if show_progress:
                print(file=sys.stderr)  # New line after progress
            
            return True
        
        except Exception as e:
            print(f"\nError downloading model: {e}", file=sys.stderr)
            # Clean up temp file if exists
            if temp_path.exists():
                temp_path.unlink()
            return False
    
    def validate_and_download_model(self, model_name: str) -> Tuple[bool, Path]:
        """
        Validate model exists and download if necessary
        Returns: (success, model_path)
        """
        model_path = self.get_model_path(model_name)
        
        # Check if model already exists
        if model_path.exists():
            print(f"✅ Model found at: {model_path}", file=sys.stderr)
            return True, model_path
        
        print(f"🔍 Model not found locally. Searching HuggingFace...", file=sys.stderr)
        
        # Query HuggingFace
        model_info = self.query_huggingface_model(model_name)
        if not model_info:
            print(f"❌ Model '{model_name}' not found on HuggingFace", file=sys.stderr)
            return False, model_path
        
        print(f"📦 Found model: {model_info.get('id', model_name)}", file=sys.stderr)
        
        # Find GGUF files
        gguf_files = self.find_gguf_files(model_info)
        if not gguf_files:
            print(f"❌ No GGUF files found for model '{model_name}'", file=sys.stderr)
            print("This model may not have GGUF format available.", file=sys.stderr)
            return False, model_path
        
        # Recommend quantization
        recommended = self.recommend_quantization(gguf_files)
        if not recommended:
            print("❌ No suitable quantization found", file=sys.stderr)
            return False, model_path
        
        print(f"\n🎯 Recommended: {recommended['filename']} ({recommended.get('size', 0) / (1024**3):.1f} GB)", file=sys.stderr)
        print(f"System capability: {self._get_system_specs()}", file=sys.stderr)
        
        # Ask for confirmation
        response = input("\nDownload this model? [Y/n]: ").strip().lower()
        if response and response != 'y':
            print("Download cancelled.", file=sys.stderr)
            return False, model_path
        
        # Download the model
        print(f"\n📥 Downloading to: {model_path}", file=sys.stderr)
        if self.download_model(recommended['url'], model_path):
            print(f"✅ Model downloaded successfully!", file=sys.stderr)
            return True, model_path
        else:
            return False, model_path


def create_default_config(config_path: Path, model_name: Optional[str] = None) -> Dict[str, Any]:
    """Create a default configuration file"""
    default_config = {
        "model": {
            "name": model_name or "mistral-small-2409",
            "path": f"~/.agentyard/models/{model_name or 'mistral-small-2409'}.gguf",
            "context_size": 32768,
            "gpu_layers": -1,  # Use all GPU layers
            "temperature": 0.1,
            "max_tokens": 4096
        },
        "models_dir": "~/.agentyard/models",
        "models": {
            # Per-model overrides can be added here
            # "model-name": {
            #     "path": "/custom/path/to/model.gguf"
            # }
        },
        "review": {
            "max_diff_lines": 1000,
            "include_pr_description": True,
            "output_format": "markdown"
        },
        "github": {
            "default_remote": "origin"
        }
    }
    
    return default_config


if __name__ == "__main__":
    # Test the model manager
    import argparse
    
    parser = argparse.ArgumentParser(description="Test model manager")
    parser.add_argument("model", help="Model name to test")
    parser.add_argument("--config", help="Config file path")
    
    args = parser.parse_args()
    
    manager = ModelManager(args.config)
    success, path = manager.validate_and_download_model(args.model)
    
    if success:
        print(f"\nModel ready at: {path}")
    else:
        print("\nModel validation/download failed")
        sys.exit(1)