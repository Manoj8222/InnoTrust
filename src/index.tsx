import { NativeModules, Platform } from 'react-native';

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

export function multiply(a: number, b: number): Promise<number> {
  return CamOcrLib.multiply(a, b);
}

export function getHelloWorld(): Promise<string> {
  return CamOcrLib.getHelloWorld();
}

export function showEkycUI(): Promise<void> {
  return CamOcrLib.showEkycUI();
}