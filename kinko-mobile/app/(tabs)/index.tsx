import { Image } from 'expo-image';
import { Platform, StyleSheet } from 'react-native';

import { HelloWave } from '@/components/hello-wave';
import ParallaxScrollView from '@/components/parallax-scroll-view';
import { ThemedText } from '@/components/themed-text';
import { ThemedView } from '@/components/themed-view';

export default function HomeScreen() {
  return (
    <ParallaxScrollView
      headerImage={<Image source={require('@/assets/images/bglogin.png')} style={{ width: '100%', height: 300 }} />}
      headerBackgroundColor={{ light: '#f67e7e', dark: '#ff0000' }}>
      <ThemedView>
        <HelloWave />
        <ThemedText>Welcome to Kinko!</ThemedText>
      </ThemedView>
    </ParallaxScrollView>

  );
}

const styles = StyleSheet.create({

});
