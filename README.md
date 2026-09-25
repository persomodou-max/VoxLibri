# 📚 VoxLibri

> Application mobile Flutter de lecture de PDF avec synthèse vocale (TTS)

[![Flutter](https://img.shields.io/badge/Flutter-3.35.1-blue?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-blue?logo=dart)](https://dart.dev)
[![License](https://img.shields.io/badge/License-MIT-green)](LICENSE)

---

## 📖 Description

**VoxLibri** est une application mobile multiplateforme (Android & iOS) développée avec Flutter, permettant d'importer des fichiers PDF et de les lire à voix haute grâce à la synthèse vocale (TTS — Text-to-Speech) native du système.

Ce projet a été réalisé dans le cadre d'un **projet universitaire à l'Université Gaston Berger (UGB)** de Saint-Louis, Sénégal.

---

## ✨ Fonctionnalités

- 📥 **Import de PDF** — Sélection de fichiers PDF depuis le stockage natif
- 🔊 **Lecture TTS** — Synthèse vocale avec prise en charge du SSML (Android) et des segments (iOS)
- 🌍 **Détection automatique de la langue** — Via Google ML Kit (traitement local)
- 🎵 **Lecture en arrière-plan** — Avec contrôles dans la barre de notification
- 📚 **Bibliothèque** — Gestion et suivi de la progression de lecture
- ⚙️ **Paramètres** — Contrôle de la vitesse, langue et préférences
- 🌗 **Thème clair/sombre** — Design moderne avec typographie Google Fonts (Outfit)

---

## 🏗️ Architecture

```
lib/
├── core/           # Constantes, exceptions, utilitaires
├── data/           # Base de données (Drift SQLite), repositories
├── domain/         # Modèles, services (PDF, TTS, segmentation)
├── features/       # Écrans (Bibliothèque, Lecteur, Paramètres, À propos)
├── providers/      # State management (Riverpod)
├── services/       # Services natifs (TTS, notifications, audio)
├── app.dart        # Configuration de l'application
└── main.dart       # Point d'entrée
```

---

## 📦 Technologies

| Dépendance | Version | Rôle |
|---|---|---|
| `flutter_riverpod` | 2.6.1 | State management |
| `drift` | 2.31.0 | Base de données SQLite |
| `syncfusion_flutter_pdf` | 26.2.14 | Extraction de texte PDF |
| `google_mlkit_language_id` | 0.10.1 | Détection de langue locale |
| `flutter_tts` | 4.x | Synthèse vocale système |
| `audio_service` | 0.18.17 | Lecture en arrière-plan |
| `file_picker` | 8.3.7 | Sélection de fichiers PDF |
| `google_fonts` | 8.1.0 | Typographie (Outfit) |

---

## 🚀 Installation et lancement

### Prérequis

- Flutter 3.35.1+
- Dart 3.x
- Android SDK (API 34) ou Xcode (iOS)
- Java JDK 17+

### Étapes

```bash
# 1. Cloner le dépôt
git clone https://github.com/persomodou-max/VoxLibri.git
cd VoxLibri

# 2. Installer les dépendances
flutter pub get

# 3. Lancer l'application
flutter run

# 4. Compiler l'APK (optionnel)
flutter build apk --release
```

### Vérifications

```bash
flutter analyze    # 0 issue
flutter test       # 100% de réussite
```

---

## 👨‍💻 Auteur

**Modou Sylla**  
Étudiant en Licence 3 — Université Gaston Berger (UGB), Saint-Louis, Sénégal

---

## 📄 Licence

Ce projet est sous licence MIT. Voir le fichier [LICENSE](LICENSE) pour plus de détails.
