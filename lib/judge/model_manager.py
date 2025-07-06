#!/usr/bin/env python3
"""
Model manager for judge command
Handles model discovery, validation, downloading, and path resolution
"""

import os
import sys
import json
import struct
import platform
from pathlib import Path
from typing import Dict, List, Optional, Tuple, Any
from urllib.parse import urlparse, quote
import hashlib
import time
from datetime import datetime, timedelta
from collections import OrderedDict

# Import these modules with error handling
try:
    import psutil
except ImportError:
    print("Warning: psutil not available. System detection will be limited.", file=sys.stderr)
    psutil = None

try:
    import requests
except ImportError:
    print("Warning: requests not available. Model downloading will be disabled.", file=sys.stderr)
    requests = None

try:
    import yaml
except ImportError:
    print("Warning: PyYAML not available. Configuration support will be limited.", file=sys.stderr)
    yaml = None


class GGUFMetadataReader:
    """Read metadata from GGUF model files"""
    
    # GGUF value type constants
    GGUF_TYPE_UINT8   = 0
    GGUF_TYPE_INT8    = 1
    GGUF_TYPE_UINT16  = 2
    GGUF_TYPE_INT16   = 3
    GGUF_TYPE_UINT32  = 4
    GGUF_TYPE_INT32   = 5
    GGUF_TYPE_FLOAT32 = 6
    GGUF_TYPE_BOOL    = 7
    GGUF_TYPE_STRING  = 8
    GGUF_TYPE_ARRAY   = 9
    GGUF_TYPE_UINT64  = 10
    GGUF_TYPE_INT64   = 11
    GGUF_TYPE_FLOAT64 = 12
    
    def __init__(self, file_path: Path):
        self.file_path = file_path
        self.metadata = OrderedDict()
    
    def read_metadata(self) -> Dict[str, Any]:
        """Read and parse GGUF metadata"""
        try:
            with open(self.file_path, 'rb') as f:
                # Read header
                magic = struct.unpack('<I', f.read(4))[0]
                if magic != 0x46554747:  # 'GGUF' in little-endian
                    raise ValueError(f"Invalid GGUF magic: {magic:08x}")
                
                version = struct.unpack('<I', f.read(4))[0]
                if version < 2:
                    raise ValueError(f"Unsupported GGUF version: {version}")
                
                tensor_count = struct.unpack('<Q', f.read(8))[0]
                metadata_kv_count = struct.unpack('<Q', f.read(8))[0]
                
                self.metadata['_header'] = {
                    'version': version,
                    'tensor_count': tensor_count,
                    'metadata_kv_count': metadata_kv_count
                }
                
                # Read metadata key-value pairs
                for _ in range(metadata_kv_count):
                    key = self._read_string(f)
                    value_type = struct.unpack('<I', f.read(4))[0]
                    value = self._read_value(f, value_type)
                    self.metadata[key] = value
                
                return self._extract_model_info()
        
        except Exception as e:
            # Return minimal metadata on error
            return {
                'error': str(e),
                'file': str(self.file_path),
                'architecture': 'unknown'
            }
    
    def _read_string(self, f) -> str:
        """Read a GGUF string"""
        length = struct.unpack('<Q', f.read(8))[0]
        return f.read(length).decode('utf-8', errors='ignore')
    
    def _read_value(self, f, value_type: int) -> Any:
        """Read a typed value"""
        if value_type == self.GGUF_TYPE_UINT8:
            return struct.unpack('B', f.read(1))[0]
        elif value_type == self.GGUF_TYPE_INT8:
            return struct.unpack('b', f.read(1))[0]
        elif value_type == self.GGUF_TYPE_UINT16:
            return struct.unpack('<H', f.read(2))[0]
        elif value_type == self.GGUF_TYPE_INT16:
            return struct.unpack('<h', f.read(2))[0]
        elif value_type == self.GGUF_TYPE_UINT32:
            return struct.unpack('<I', f.read(4))[0]
        elif value_type == self.GGUF_TYPE_INT32:
            return struct.unpack('<i', f.read(4))[0]
        elif value_type == self.GGUF_TYPE_FLOAT32:
            return struct.unpack('<f', f.read(4))[0]
        elif value_type == self.GGUF_TYPE_BOOL:
            return struct.unpack('B', f.read(1))[0] != 0
        elif value_type == self.GGUF_TYPE_STRING:
            return self._read_string(f)
        elif value_type == self.GGUF_TYPE_ARRAY:
            # Read array type and length
            array_type = struct.unpack('<I', f.read(4))[0]
            array_length = struct.unpack('<Q', f.read(8))[0]
            # For now, skip array data
            return f"[Array of {array_length} items]"
        elif value_type == self.GGUF_TYPE_UINT64:
            return struct.unpack('<Q', f.read(8))[0]
        elif value_type == self.GGUF_TYPE_INT64:
            return struct.unpack('<q', f.read(8))[0]
        elif value_type == self.GGUF_TYPE_FLOAT64:
            return struct.unpack('<d', f.read(8))[0]
        else:
            return f"[Unknown type {value_type}]"
    
    def _extract_model_info(self) -> Dict[str, Any]:
        """Extract relevant model information from metadata"""
        # Map file_type numbers to quantization names
        quant_map = {
            0: "F32", 1: "F16",
            2: "Q4_0", 3: "Q4_1", 7: "Q8_0",
            8: "Q5_0", 9: "Q5_1", 10: "Q2_K",
            11: "Q3_K_S", 12: "Q3_K_M", 13: "Q3_K_L",
            14: "Q4_K_S", 15: "Q4_K_M", 16: "Q5_K_S",
            17: "Q5_K_M", 18: "Q6_K"
        }
        
        file_type = self.metadata.get('general.file_type', -1)
        quantization = quant_map.get(file_type, f"Unknown ({file_type})")
        
        info = {
            'architecture': self.metadata.get('general.architecture', 'unknown'),
            'name': self.metadata.get('general.name', 'unknown'),
            'quantization': quantization,
            'file_type': file_type,
            'context_length': None,
            'parameters': {}
        }
        
        # Extract architecture-specific info
        arch = info['architecture']
        if arch in ['llama', 'mistral']:
            info['context_length'] = self.metadata.get(f'{arch}.context_length')
            info['parameters'] = {
                'block_count': self.metadata.get(f'{arch}.block_count'),
                'embedding_length': self.metadata.get(f'{arch}.embedding_length'),
                'feed_forward_length': self.metadata.get(f'{arch}.feed_forward_length'),
                'attention_heads': self.metadata.get(f'{arch}.attention.head_count'),
                'attention_heads_kv': self.metadata.get(f'{arch}.attention.head_count_kv'),
            }
        
        # Add file size
        try:
            info['file_size_gb'] = self.file_path.stat().st_size / (1024 ** 3)
        except:
            info['file_size_gb'] = 0
        
        return info


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
        
        if yaml is None:
            print("Warning: PyYAML not installed. Cannot load configuration.", file=sys.stderr)
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
        
        Models are stored in namespace/model folder structure.
        """
        # Check for per-model path in config
        if self.config:
            model_config = self.config.get('models', {}).get(model_name, {})
            if 'path' in model_config:
                return Path(os.path.expanduser(model_config['path']))
        
        # Parse namespace and model from model_name
        if '/' in model_name:
            namespace, model = model_name.split('/', 1)
        else:
            # If no namespace provided, use 'default'
            namespace = 'default'
            model = model_name
        
        # Base directory resolution
        base_dir = None
        
        # Check environment variable
        env_path = os.environ.get('AGENTYARD_MODELS_PATH')
        if env_path:
            base_dir = Path(os.path.expanduser(env_path))
        # Check config file models_dir
        elif self.config and 'models_dir' in self.config:
            base_dir = Path(os.path.expanduser(self.config['models_dir']))
        # Default path
        else:
            base_dir = Path.home() / ".agentyard" / "models"
        
        # Return path in namespace/model structure
        # Look for any .gguf file in the model directory
        return base_dir / namespace / model
    
    def _get_system_specs(self) -> str:
        """Determine system capability level based on RAM and GPU"""
        if psutil is None:
            print("Warning: psutil not available. Assuming medium system specs.", file=sys.stderr)
            return "medium"
            
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
        if requests is None:
            print("Warning: requests module not available. Cannot query HuggingFace.", file=sys.stderr)
            return None
            
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
        if requests is None:
            print("Error: requests module not available. Cannot download models.", file=sys.stderr)
            return False
            
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
    
    def validate_and_download_model(self, model_name: str, force: bool = False) -> Tuple[bool, Path]:
        """
        Validate model exists and download if necessary
        Returns: (success, model_path)
        """
        model_dir = self.get_model_path(model_name)
        
        # Check if model directory exists and contains GGUF files
        if model_dir.exists() and model_dir.is_dir():
            gguf_files = list(model_dir.glob("*.gguf"))
            if gguf_files:
                # Use the first GGUF file found
                model_path = gguf_files[0]
                print(f"✅ Model found at: {model_path}", file=sys.stderr)
                return True, model_path
        
        print(f"🔍 Model not found locally. Searching HuggingFace...", file=sys.stderr)
        
        # Query HuggingFace
        model_info = self.query_huggingface_model(model_name)
        if not model_info:
            print(f"❌ Model '{model_name}' not found on HuggingFace", file=sys.stderr)
            return False, model_dir
        
        print(f"📦 Found model: {model_info.get('id', model_name)}", file=sys.stderr)
        
        # Find GGUF files
        gguf_files = self.find_gguf_files(model_info)
        if not gguf_files:
            print(f"❌ No GGUF files found for model '{model_name}'", file=sys.stderr)
            print("This model may not have GGUF format available.", file=sys.stderr)
            return False, model_dir
        
        # Recommend quantization
        recommended = self.recommend_quantization(gguf_files)
        if not recommended:
            print("❌ No suitable quantization found", file=sys.stderr)
            return False, model_dir
        
        print(f"\n🎯 Recommended: {recommended['filename']} ({recommended.get('size', 0) / (1024**3):.1f} GB)", file=sys.stderr)
        print(f"System capability: {self._get_system_specs()}", file=sys.stderr)
        
        # Ask for confirmation if not forced and TTY is available
        if not force and sys.stdin.isatty():
            response = input("\nDownload this model? [Y/n]: ").strip().lower()
            if response and response != 'y':
                print("Download cancelled.", file=sys.stderr)
                return False, model_dir
        elif not force:
            # Non-interactive mode, default to no
            print("\nNon-interactive mode detected. Use --force to download automatically.", file=sys.stderr)
            print("Download cancelled.", file=sys.stderr)
            return False, model_dir
        else:
            print("\nForce mode enabled, downloading automatically...", file=sys.stderr)
        
        # Download the model
        # Create the full path with the actual filename
        model_file_path = model_dir / recommended['filename']
        print(f"\n📥 Downloading to: {model_file_path}", file=sys.stderr)
        if self.download_model(recommended['url'], model_file_path):
            print(f"✅ Model downloaded successfully!", file=sys.stderr)
            return True, model_file_path
        else:
            return False, model_file_path


def create_default_config(config_path: Path, model_name: Optional[str] = None) -> Dict[str, Any]:
    """Create a default configuration file"""
    if yaml is None:
        raise ImportError("PyYAML is required to create configuration files")
        
    default_model = model_name or "mistralai/Mistral-7B-Instruct-v0.3"
    default_config = {
        "model": {
            "name": default_model,
            "context_size": 32768,
            "gpu_layers": -1,  # Use all GPU layers
            "temperature": 0.1,
            "max_tokens": 4096
        },
        "models_dir": "~/.agentyard/models",
        "models": {
            # Per-model overrides can be added here
            # Example:
            # "mistralai/mistral-7b": {
            #     "path": "/custom/path/to/mistral-7b-model.gguf"
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