import { initializeApp } from "firebase/app";
import { getAuth, GoogleAuthProvider } from "firebase/auth"
const firebaseConfig = {
  apiKey: import.meta.env.VITE_FIREBASE_API_KEY,
  authDomain: "aihub-e81dc.firebaseapp.com",
  projectId: "aihub-e81dc",
  storageBucket: "aihub-e81dc.firebasestorage.app",
  messagingSenderId: "474494018707",
  appId: "1:474494018707:web:633f12bbcadbdd5d9b1966",
  measurementId: "G-PSRZ0PKQE4"
};

// Initialize Firebase
const app = initializeApp(firebaseConfig);
export const auth=getAuth(app)
export const googleProvider=new GoogleAuthProvider()