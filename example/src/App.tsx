import React from 'react';
import {
  View,
  StyleSheet,
  Alert,
  SafeAreaView,
  TouchableOpacity,
  Text,
} from 'react-native';
import { showEkycUI } from 'react-native-cam-ocr-lib';

export default function App() {
  const startEkyc = async () => {
    try {
      await showEkycUI();
    } catch (error) {
      Alert.alert('Error', 'Failed to launch eKYC');
    }
  };

  return (
    <SafeAreaView style={styles.container}>
      <TouchableOpacity style={styles.button} onPress={startEkyc}>
        <Text style={styles.buttonText}>Launch eKYC</Text>
      </TouchableOpacity>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: 'flex-end',
  },
  button: {
    backgroundColor: '#007BFF', // Custom background color
    padding: 15,
    margin: 20,
    borderRadius: 5,
    alignItems: 'center',
  },
  buttonText: {
    color: '#FFFFFF', // Custom text color
    fontSize: 16,
    fontWeight: 'bold',
  },
});
