import MaterialIcons from "@expo/vector-icons/MaterialIcons";
import { Image } from "expo-image";
import { StyleSheet, View } from "react-native";

export default function Header() {
  return (
    <View style={styles.headerContainer}>
      <View>
        <Image
          source={require('@/assets/images/logo.png')}
          style={{ width: 120, height: 30, alignSelf: 'center', marginTop: 50 }}
          contentFit="contain"
        />
      </View>
      <View style={styles.headerIcon}>
        <MaterialIcons name="notifications" size={24} color="red" />
      </View>
    </View>
  )
}


const styles = StyleSheet.create({
  headerContainer: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingHorizontal: 20,
  },
  headerIcon: {
    position: 'absolute',
    right: 20,
    top: 50,
  },
});
