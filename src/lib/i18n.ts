import i18n from "i18next";
import { initReactI18next } from "react-i18next";
import ar from "../locales/ar.json";
import en from "../locales/en.json";

export const setLanguage = (lang: string) => {
  const current = lang === "en" ? "en" : "ar";
  i18n.changeLanguage(current);
  document.documentElement.dir = current === "ar" ? "rtl" : "ltr";
  document.documentElement.lang = current;
};

i18n.use(initReactI18next).init({
  resources: {
    ar: { translation: ar },
    en: { translation: en },
  },
  lng: "ar",
  fallbackLng: "ar",
  interpolation: {
    escapeValue: false,
  },
});

export default i18n;
