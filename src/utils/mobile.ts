import { App } from '@capacitor/app';
import { SplashScreen } from '@capacitor/splash-screen';
import { StatusBar, Style } from '@capacitor/status-bar';
import { Network } from '@capacitor/network';

export const initializeMobileApp = async () => {
  try {
    await StatusBar.setStyle({ style: Style.Light });
    await StatusBar.setBackgroundColor({ color: '#F59E0B' });

    await SplashScreen.hide();

    const status = await Network.getStatus();
    console.log('Network status:', status);

    Network.addListener('networkStatusChange', status => {
      console.log('Network status changed', status);
      if (!status.connected) {
        alert('تم فقد الاتصال بالإنترنت. بعض الميزات قد لا تعمل بشكل صحيح.');
      }
    });

    App.addListener('appStateChange', ({ isActive }) => {
      console.log('App state changed. Is active?', isActive);
    });

    App.addListener('backButton', ({ canGoBack }) => {
      if (!canGoBack) {
        App.exitApp();
      } else {
        window.history.back();
      }
    });
  } catch (error) {
    console.error('Error initializing mobile app:', error);
  }
};

export const isMobile = () => {
  return /Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(
    navigator.userAgent
  );
};

export const isNativeApp = () => {
  return (window as any).Capacitor !== undefined;
};

export const checkNetworkStatus = async () => {
  try {
    const status = await Network.getStatus();
    return status.connected;
  } catch (error) {
    console.error('Error checking network status:', error);
    return true;
  }
};
