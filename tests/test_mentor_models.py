#!/usr/bin/env python3
"""
Test script for mentor command model-specific parameter handling
"""
import unittest
from unittest.mock import Mock, patch, MagicMock
import sys
import os

# Add the bin directory to the path so we can import the mentor module
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'bin'))

# Mock the openai module before importing mentor
sys.modules['openai'] = Mock()

# Now we can import the functions from mentor
from mentor import call_openai_api

class TestMentorModelHandling(unittest.TestCase):
    """Test model-specific parameter handling in mentor command"""
    
    @patch('mentor.openai.OpenAI')
    def test_o3_model_no_temperature(self, mock_openai_class):
        """Test that o3 models don't include temperature parameter"""
        # Setup mock
        mock_client = Mock()
        mock_openai_class.return_value = mock_client
        
        mock_response = Mock()
        mock_response.choices = [Mock(message=Mock(content='{"findings": []}'))]
        mock_client.chat.completions.create.return_value = mock_response
        
        # Test with o3 model
        prompt = "Test prompt"
        api_key = "test-key"
        model = "o3"
        
        result = call_openai_api(prompt, api_key, model)
        
        # Verify the API was called without temperature parameter
        mock_client.chat.completions.create.assert_called_once()
        call_args = mock_client.chat.completions.create.call_args
        
        # Check that temperature is NOT in the parameters
        self.assertNotIn('temperature', call_args.kwargs)
        # Check that other required parameters are present
        self.assertEqual(call_args.kwargs['model'], 'o3')
        self.assertEqual(call_args.kwargs['response_format'], {"type": "json_object"})
        
    @patch('mentor.openai.OpenAI')
    def test_o3_mini_model_no_temperature(self, mock_openai_class):
        """Test that o3-mini models don't include temperature parameter"""
        # Setup mock
        mock_client = Mock()
        mock_openai_class.return_value = mock_client
        
        mock_response = Mock()
        mock_response.choices = [Mock(message=Mock(content='{"findings": []}'))]
        mock_client.chat.completions.create.return_value = mock_response
        
        # Test with o3-mini model
        prompt = "Test prompt"
        api_key = "test-key"
        model = "o3-mini"
        
        result = call_openai_api(prompt, api_key, model)
        
        # Verify the API was called without temperature parameter
        mock_client.chat.completions.create.assert_called_once()
        call_args = mock_client.chat.completions.create.call_args
        
        # Check that temperature is NOT in the parameters
        self.assertNotIn('temperature', call_args.kwargs)
        
    @patch('mentor.openai.OpenAI')
    def test_gpt4_model_with_temperature(self, mock_openai_class):
        """Test that non-o3 models include temperature parameter"""
        # Setup mock
        mock_client = Mock()
        mock_openai_class.return_value = mock_client
        
        mock_response = Mock()
        mock_response.choices = [Mock(message=Mock(content='{"findings": []}'))]
        mock_client.chat.completions.create.return_value = mock_response
        
        # Test with gpt-4 model
        prompt = "Test prompt"
        api_key = "test-key"
        model = "gpt-4"
        
        result = call_openai_api(prompt, api_key, model)
        
        # Verify the API was called with temperature parameter
        mock_client.chat.completions.create.assert_called_once()
        call_args = mock_client.chat.completions.create.call_args
        
        # Check that temperature IS in the parameters
        self.assertIn('temperature', call_args.kwargs)
        self.assertEqual(call_args.kwargs['temperature'], 0.3)
        
    @patch('mentor.openai.OpenAI')
    def test_gpt4o_model_with_temperature(self, mock_openai_class):
        """Test that gpt-4o model includes temperature parameter"""
        # Setup mock
        mock_client = Mock()
        mock_openai_class.return_value = mock_client
        
        mock_response = Mock()
        mock_response.choices = [Mock(message=Mock(content='{"findings": []}'))]
        mock_client.chat.completions.create.return_value = mock_response
        
        # Test with gpt-4o model
        prompt = "Test prompt"
        api_key = "test-key"
        model = "gpt-4o"
        
        result = call_openai_api(prompt, api_key, model)
        
        # Verify the API was called with temperature parameter
        mock_client.chat.completions.create.assert_called_once()
        call_args = mock_client.chat.completions.create.call_args
        
        # Check that temperature IS in the parameters
        self.assertIn('temperature', call_args.kwargs)
        self.assertEqual(call_args.kwargs['temperature'], 0.3)

if __name__ == '__main__':
    # Run the tests
    unittest.main(verbosity=2)