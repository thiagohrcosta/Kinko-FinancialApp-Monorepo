import type { Metadata } from "next";
import { Roboto } from "next/font/google";
import "./globals.css";

// Same font as the mobile app (@expo-google-fonts/roboto 400/700)
const roboto = Roboto({
  variable: "--font-roboto",
  subsets: ["latin"],
  weight: ["400", "500", "700"],
});

export const metadata: Metadata = {
  title: "Kinko",
  description: "Kinko — ledger-driven digital banking",
};

export default function RootLayout({ children }: LayoutProps<"/">) {
  return (
    <html lang="en" className={`${roboto.variable} h-full antialiased`}>
      <body className="flex min-h-full flex-col">{children}</body>
    </html>
  );
}
