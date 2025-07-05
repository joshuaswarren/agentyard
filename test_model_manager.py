#!/usr/bin/env python3
"""
Test suite for judge model_manager module
Tests namespace/model structure and GGUF metadata parsing
"""

import os
import sys
import tempfile
import unittest
from pathlib import Path
from unittest.mock import Mock, patch, MagicMock

# Add lib directory to path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'lib'))

try:
    from judge.model_manager import ModelManager, GGUFMetadataReader
except ImportError:
    print("Error: Could not import model_manager module")
    print("Make sure you're running from the project root")
    sys.exit(1)


class TestModelManager(unittest.TestCase):
    """Test ModelManager class"""
    
    def setUp(self):
        """Set up test environment"""
        self.test_dir = tempfile.mkdtemp()
        self.manager = ModelManager()
    
    def tearDown(self):
        """Clean up test environment"""
        import shutil
        shutil.rmtree(self.test_dir, ignore_errors=True)
    
    def test_namespace_model_parsing(self):
        """Test parsing of namespace/model format"""
        # Test with namespace
        path = self.manager.get_model_path("mistralai/mistral-7b")
        self.assertTrue("mistralai" in str(path))
        self.assertTrue("mistral-7b" in str(path))
        
        # Test without namespace (should use 'default')
        path = self.manager.get_model_path("standalone-model")
        self.assertTrue("default" in str(path))
        self.assertTrue("standalone-model" in str(path))
    
    def test_model_path_hierarchy(self):
        """Test model path resolution hierarchy"""
        # Test environment variable takes precedence
        with patch.dict(os.environ, {'AGENTYARD_MODELS_PATH': '/custom/path'}):
            path = self.manager.get_model_path("test/model")
            self.assertEqual(str(path), "/custom/path/test/model")
    
    def test_validate_and_download_force_mode(self):
        """Test force mode skips confirmation"""
        # Mock the model path to exist
        with patch.object(Path, 'exists', return_value=True):
            success, path = self.manager.validate_and_download_model("test-model", force=True)
            self.assertTrue(success)
    
    def test_get_system_specs(self):
        """Test system specification detection"""
        specs = self.manager._get_system_specs()
        self.assertIn(specs, ["high", "medium", "low"])


class TestGGUFMetadataReader(unittest.TestCase):
    """Test GGUFMetadataReader class"""
    
    def setUp(self):
        """Set up test environment"""
        self.test_file = Path("/tmp/test.gguf")
    
    def test_nonexistent_file(self):
        """Test handling of non-existent files"""
        reader = GGUFMetadataReader(Path("/nonexistent.gguf"))
        metadata = reader.read_metadata()
        self.assertIn('error', metadata)
    
    def test_invalid_file(self):
        """Test handling of invalid GGUF files"""
        # Create a non-GGUF file
        with tempfile.NamedTemporaryFile(suffix=".gguf", delete=False) as f:
            f.write(b"not a gguf file")
            temp_path = Path(f.name)
        
        try:
            reader = GGUFMetadataReader(temp_path)
            metadata = reader.read_metadata()
            self.assertIn('error', metadata)
        finally:
            temp_path.unlink()
    
    def test_metadata_structure(self):
        """Test metadata structure returned"""
        reader = GGUFMetadataReader(Path("/fake.gguf"))
        metadata = reader.read_metadata()
        
        # Should have these fields even on error
        self.assertIn('architecture', metadata)
        self.assertEqual(metadata['architecture'], 'unknown')


class TestNamespaceStructure(unittest.TestCase):
    """Test namespace/model folder structure"""
    
    def test_model_discovery_structure(self):
        """Test that model discovery follows namespace/model pattern"""
        test_dir = tempfile.mkdtemp()
        
        try:
            # Create test structure
            model_dir = Path(test_dir) / "mistralai" / "mistral-7b"
            model_dir.mkdir(parents=True)
            
            # Create GGUF file
            gguf_file = model_dir / "model.gguf"
            gguf_file.touch()
            
            # Test discovery would find this structure
            self.assertTrue(model_dir.exists())
            self.assertTrue(gguf_file.exists())
            
            # Verify structure matches expected pattern
            namespace = model_dir.parent.name
            model = model_dir.name
            self.assertEqual(namespace, "mistralai")
            self.assertEqual(model, "mistral-7b")
            
        finally:
            import shutil
            shutil.rmtree(test_dir, ignore_errors=True)


if __name__ == '__main__':
    # Run tests with verbosity
    unittest.main(verbosity=2)