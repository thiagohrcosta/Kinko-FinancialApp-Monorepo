import { ThemedView } from "@/components/themed-view";
import { useAuth } from "@/context/auth-context";
import { LinearGradient } from "expo-linear-gradient";
import { router } from "expo-router";
import { useState } from "react";
import { Alert, ImageBackground, Pressable, StyleSheet, Text, TextInput, View } from "react-native";

export default function LoginScreen() {
  const [rememberMe, setRememberMe] = useState(false);
  const { login } = useAuth();
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");

  const handleLogin = async () => {
    setError(null)

    if (!email || !password) {
      setError("Please enter both email and password.");
      return;
    }

    setIsLoading(true);

    try {
      await login(email, password);
      router.replace('/(tabs)');
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Login failed';
      setError(message);
      Alert.alert('Login Error', message);
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <ImageBackground
      source={require("@/assets/images/bglogin.png")}
      style={styles.container}
      imageStyle={styles.backgroundImage}
      resizeMode="cover"
    >
      <ThemedView style={styles.content}>
        <View style={styles.header}>
          <Text style={styles.welcomeText}>Welcome to</Text>
          <Text style={styles.kinkoText}>Kinko!</Text>
        </View>

        <View style={styles.card}>
          <View style={styles.inputRow}>
            <View style={styles.inputIcon}>
              <View style={styles.iconDot} />
            </View>
            <TextInput
              placeholder="Username"
              placeholderTextColor="#7a7a7a"
              style={styles.input}
              autoCapitalize="none"
              onChangeText={setEmail}
            />
          </View>
          <View style={styles.divider} />
          <View style={styles.inputRow}>
            <View style={styles.inputIcon}>
              <View style={styles.iconLockBody}>
                <View style={styles.iconLockShackle} />
              </View>
            </View>
            <TextInput
              placeholder="Password"
              placeholderTextColor="#7a7a7a"
              style={styles.input}
              secureTextEntry
              onChangeText={setPassword}
            />
            <Text style={styles.chevron}>{">"}</Text>
          </View>

          <Pressable
            onPress={handleLogin}
            disabled={isLoading}
          >
            <LinearGradient
              colors={["#ff3b3b", "#b30000"]}
              start={{ x: 0, y: 0 }}
              end={{ x: 1, y: 0 }}
              style={styles.loginButton}
            >
              <Text style={styles.loginButtonText}>Log In</Text>
            </LinearGradient>
          </Pressable>

          <View style={styles.optionsRow}>
            <Pressable
              style={styles.rememberRow}
              onPress={() => setRememberMe((value) => !value)}
            >
              <View style={[styles.checkbox, rememberMe && styles.checkboxChecked]}>
                {rememberMe ? <View style={styles.checkboxDot} /> : null}
              </View>
              <Text style={styles.optionText}>Remember me</Text>
            </Pressable>
            <Pressable>
              <Text style={styles.forgotText}>Forgot password?</Text>
            </Pressable>
          </View>
        </View>
      </ThemedView>
    </ImageBackground>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    padding: 20,
  },
  content: {
    flex: 1,
    backgroundColor: "transparent",
    alignItems: "center",
    paddingTop: 24,
    paddingBottom: 40,
  },
  backgroundImage: {
    opacity: 0.9,
  },
  header: {
    width: "100%",
    paddingHorizontal: 6,
    marginBottom: 300
  },
  welcomeText: {
    fontSize: 42,
    color: "#2c2c2c",
    fontFamily: "Roboto_400Regular",
    letterSpacing: 0.5,
  },
  kinkoText: {
    fontSize: 48,
    fontFamily: "Roboto_700Bold",
    color: "#d01c1c",
    marginTop: -4,
  },
  card: {
    width: "100%",
    maxWidth: 360,
    padding: 20,
    borderRadius: 22,
    backgroundColor: "rgba(255,255,255,0.75)",
    borderWidth: 1,
    borderColor: "rgba(255,255,255,0.4)",
    shadowColor: "#000",
    shadowOpacity: 0.25,
    shadowRadius: 20,
    shadowOffset: { width: 0, height: 10 },
    elevation: 10,
  },
  inputRow: {
    flexDirection: "row",
    alignItems: "center",
    gap: 10,
    paddingHorizontal: 6,
    paddingVertical: 4,
  },
  input: {
    flex: 1,
    height: 42,
    borderRadius: 10,
    backgroundColor: "transparent",
    paddingHorizontal: 6,
    color: "#1e1e1e",
    fontFamily: "Roboto_400Regular",
  },
  inputIcon: {
    width: 28,
    height: 28,
    borderRadius: 14,
    backgroundColor: "rgba(205, 196, 196, 0.35)",
    alignItems: "center",
    justifyContent: "center",
  },
  iconDot: {
    width: 8,
    height: 8,
    borderRadius: 4,
    backgroundColor: "#8c8c8c",
  },
  iconLockBody: {
    width: 12,
    height: 10,
    borderRadius: 3,
    backgroundColor: "#8c8c8c",
    alignItems: "center",
    justifyContent: "flex-start",
    paddingTop: 1,
  },
  iconLockShackle: {
    width: 10,
    height: 6,
    borderRadius: 3,
    borderWidth: 1.5,
    borderColor: "#8c8c8c",
    borderBottomWidth: 0,
    marginTop: -6,
  },
  divider: {
    height: 1,
    backgroundColor: "rgba(180, 170, 170, 0.55)",
    marginVertical: 6,
    marginHorizontal: 6,
  },
  chevron: {
    fontSize: 18,
    color: "#b7b0b0",
  },
  loginButton: {
    marginTop: 16,
    height: 50,
    borderRadius: 16,
    alignItems: "center",
    justifyContent: "center",
  },
  loginButtonText: {
    color: "#fff",
    fontSize: 16,
    fontFamily: "Roboto_700Bold",
  },
  optionsRow: {
    marginTop: 14,
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "space-between",
  },
  rememberRow: {
    flexDirection: "row",
    alignItems: "center",
    gap: 8,
  },
  checkbox: {
    width: 16,
    height: 16,
    borderRadius: 4,
    borderWidth: 1,
    borderColor: "#bdb6b6",
    alignItems: "center",
    justifyContent: "center",
    backgroundColor: "rgba(255, 255, 255, 0.8)",
  },
  checkboxChecked: {
    borderColor: "#d22a2a",
    backgroundColor: "#d22a2a",
  },
  checkboxDot: {
    width: 6,
    height: 6,
    borderRadius: 3,
    backgroundColor: "#fff",
  },
  optionText: {
    color: "#6b6b6b",
    fontSize: 12,
  },
  forgotText: {
    color: "#c02a2a",
    fontSize: 12,
    fontWeight: "500",
  },
});