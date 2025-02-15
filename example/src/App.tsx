import React, { useEffect, useState } from 'react';
import {
  View,
  StyleSheet,
  Alert,
  SafeAreaView,
  TouchableOpacity,
  Text,
} from 'react-native';
import { showEkycUI, camOcrLibEmitter, VERIFICATION_COMPLETE_EVENT } from 'react-native-cam-ocr-lib';
import { NativeEventEmitter, NativeModules } from 'react-native';
import VerificationScreen from './Verification';

const { LivelinessDetectionBridge } = NativeModules;

export default function App() {

  const [referenceID, setReferenceID] = useState<string | null>(null);
  const [clicked, setClicked] = useState<boolean>(false);

  useEffect(() => {
    const eventEmitter = new NativeEventEmitter(LivelinessDetectionBridge);
    
    // ✅ Listen for the event
    const subscription = eventEmitter.addListener("onReferenceIDReceived", (event) => {
      console.log("✅ Reference ID received from native:", event.referenceID);
      setReferenceID(event.referenceID);
    });

    return () => {
      subscription.remove();
    };
  }, []);

  const startEkyc = async () => {
    setClicked(true);
    try {
      await showEkycUI();
    } catch (error) {
      Alert.alert('Error', 'Failed to launch eKYC');
    }
  };

  const handleCloseVerification = () => {
    setClicked(false);
    setReferenceID(null);
  };
  if(!referenceID && !clicked){
    return (
      <SafeAreaView style={styles.container}>
        <TouchableOpacity style={styles.button} onPress={startEkyc}>
          <Text style={styles.buttonText}>Launch eKYC</Text>
        </TouchableOpacity>
      </SafeAreaView>
    );
  }
  if (referenceID && clicked) {
    console.log(referenceID,"-------------++++++--------------")
    return <VerificationScreen referenceID={{ referenceID }} onClose={handleCloseVerification} />;
  }

  
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
