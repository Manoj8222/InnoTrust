import { NativeModules, Platform, NativeEventEmitter } from 'react-native';

const LINKING_ERROR =
  `The package 'react-native-cam-ocr-lib' doesn't seem to be linked. Make sure: \n\n` +
  Platform.select({ ios: "- You have run 'pod install'\n", default: '' }) +
  '- You rebuilt the app after installing the package\n' +
  '- You are not using Expo Go\n';

const CamOcrLib = NativeModules.CamOcrLib
  ? NativeModules.CamOcrLib
  : new Proxy(
      {},
      {
        get() {
          throw new Error(LINKING_ERROR);
        },
      }
    );

const camOcrLibEmitter = new NativeEventEmitter(CamOcrLib); // ✅ Add Event Emitter

// ✅ Multiply Function (Existing)
export function multiply(a: number, b: number): Promise<number> {
  return CamOcrLib.multiply(a, b);
}

// ✅ Get Hello World (Existing)
export function getHelloWorld(): Promise<string> {
  return CamOcrLib.getHelloWorld();
}

// ✅ Show EKYC UI (Existing)
export function showEkycUI(): Promise<void> {
  return CamOcrLib.showEkycUI();
}

// ✅ Start Liveliness Detection & Receive `referenceID`
export function startLivelinessDetection(callback: (referenceID: string) => void) {
  const subscription = camOcrLibEmitter.addListener('onReferenceIDReceived', (referenceID: string) => {
    console.log('✅ Received Reference ID from iOS:', referenceID);
    callback(referenceID);
  });

  CamOcrLib.startLivelinessDetection();

  return () => {
    subscription.remove(); // Cleanup listener when not needed
  };
}


// Export event emitter and event name
// export const VERIFICATION_COMPLETE_EVENT = 'VerificationComplete';
// export { camOcrLibEmitter };