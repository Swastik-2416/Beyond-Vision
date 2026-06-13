# Beyond Vision 👁️✋

**Beyond Vision** is an accessibility-focused iOS Swift Playgrounds app (`.swiftpm`) designed to help users, particularly those with visual impairments, "feel" and explore their visual environment. By blending real-time computer vision, intelligent spatial hit-testing, and dynamic haptic feedback, the app translates visual components into tactile sensations and spoken words.

Developed using Swift 6, SwiftUI, Vision, CoreML, and CoreHaptics, this project was built for the **Apple Swift Student Challenge**.

---

## 🌟 Key Features

*   **Tactile Image Exploration (Explore Mode):** Import or select images and drag your finger across the screen. As your finger glides over detected objects, the Taptic Engine generates continuous haptic feedback that intensifies as you get closer to the center of the object.
*   **Real-time Live Scanning (Live Mode):** Point the camera at your surroundings to analyze and feel objects, structures, and text in real time.
*   **Multi-Stage Vision Pipeline:** 
    1.  *Object & Animal Detection:* Runs a custom YOLO-based CoreML model alongside Apple's native Animal Recognizer.
    2.  *Saliency Fallback:* Uses objectness-based saliency mapping to find general areas of interest that the ML models might have missed.
    3.  *Region Refinement:* Triggers fine-grained image classification bounded to detected regions to provide highly specific labels (e.g., turning "dog" into "golden retriever").
    4.  *Text Recognition:* Uses OCR to read signs, labels, and text out loud.
*   **Dynamic Spatial Haptics:** Maps the distance between the user's touch point and the centroid of the nearest object to haptic intensity in real time.
*   **Interactive Text-to-Speech (TTS):** Uses `AVSpeechSynthesizer` to read object labels aloud the moment a user's finger makes contact with them.
*   **Haptic Tuner & Settings:** Allows users to adjust baseline haptic intensity, sharpness, and toggle features like text recognition to suit their sensory preferences.

---

## 🛠️ Architecture & Core Components

The codebase is organized cleanly using modular SwiftUI architecture:

```
Beyond Vision.swiftpm/
├── App/                  # Application routing and main bootstrap
│   ├── BeyondVisionApp.swift
│   ├── AppRouter.swift
│   ├── RootView.swift
│   └── MainTabView.swift
├── Core/                 # Core engines and shared business logic
│   ├── CameraManager.swift  # Sets up and manages AVCaptureSession
│   ├── VisionManager.swift  # Implements the multi-pass Vision & CoreML pipeline
│   ├── HapticManager.swift  # Manages the continuous CoreHaptics engine
│   └── Theme.swift          # Custom design system tokens
├── Features/             # UI Features and modules
│   ├── Explore/          # Image exploration touch screen
│   ├── Live/             # Live camera preview and scan view
│   ├── Settings/         # Settings panel & feedback options
│   ├── Onboarding/       # Welcome screens and interactive guide
│   └── Splash/           # Opening transition sequence
└── Resources/            # Compiled ML models and assets
```

### Technical Highlight: The Vision-to-Haptic Pipeline

1.  **Frame Capture:** `CameraManager` streams video frames to the `VisionManager` via `CVPixelBuffer`.
2.  **Parallel Detection Requests:** `VisionManager` processes YOLO, animal, and saliency requests on a dedicated background queue.
3.  **Proximity Calculation:** When a user touches the screen, `hitTest(at:size:)` calculates the distance ($d$) from the touch point to the center of the bounding box:
    $$\text{intensity} = 1.0 - \left(\frac{d}{\text{radius}} \times 0.6\right)$$
4.  **Haptic Modulation:** `HapticManager` uses `CHHapticAdvancedPatternPlayer` to dynamically update the live continuous haptic parameters:
    *   **Intensity:** Scaled dynamically by the hit-test distance and the user's system preferences.
    *   **Sharpness:** Driven by user-customized crispness configurations.
5.  **Audio Output:** `AVSpeechSynthesizer` announces the object label when transitioning onto a new target.

---

## 🚀 Requirements

*   **iOS / iPadOS Device:** Required to experience custom haptic feedback (Taptic Engine) and camera scanning.
*   **Development Tools:** Xcode 15+ or Swift Playgrounds 4.4+.
*   **Dependencies:** Runs on native Apple frameworks (`SwiftUI`, `Vision`, `CoreML`, `CoreHaptics`, `AVFoundation`).

---

## ⚙️ How to Build and Run

1.  Download or clone the project directory:
    ```bash
    git clone https://github.com/Swastik-2416/Beyond-Vision.git
    ```
2.  Double-click **`Beyond Vision.swiftpm`** on a Mac to open it in **Swift Playgrounds** or **Xcode**.
3.  Ensure your target is set to a physical iOS/iPadOS device (Simulators do not support CoreHaptics or camera feeds).
4.  Build and Run!
