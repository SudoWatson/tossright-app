# TossRight: Waste classifier and disposal instructions

![3 Screenshots of the app looping](./screenshots/screenshots.gif)

# Overview
TossRight is a mobile application that is currently primarily a way to crowd-source images of house-hold waste to train a Computer Vision model to classify the waste stream, and secondarily to be used to help identify and instruct on how to best dispose of said item (currently not really useufl, but as model is further trained, improved, and becomes more granular, it can eventually become a useful app on its own). As it's primarily a way of gather images for model improvement, all images taken with the app are uploaded to a server to improve the computer vision model.

[![License: AGPL v3](https://img.shields.io/badge/License-AGPL_v3-blue.svg)](https://www.gnu.org/licenses/agpl-3.0)  ![GitHub Release](https://img.shields.io/github/v/release/SudoWatson/tossright-app)


### Notices
> [!IMPORTANT]
> Images taken with this app WILL be uploaded to a server to be used to further train the model. An opt-out/opt-in will be provided in the near-future, but is not implemented. There is no way to delete these images once sent to the server, as there is no way to trace them back to you. Track status on issue [#1](https://github.com/SudoWatson/tossright-app/issues/1) for updates to this. One of the primary purposes of this app is to be a crowdsourced approach to creating an open Waste Identification model to be used by others.

> [!WARNING]
> The model is not 100% accurate and will often give incorrect results. Please provide feedback using the available buttons when this happens to improve the model and make it more accurate. Every image helps.


## Installation
The app is in the process of being published to app repositories like F-Droid and Google Play Store.

Android users can download and install the apk file from the **Releases** tab on the right.

As I do not own any Apple devices, I am unable to test or build apps for Apple devices.

## Develop
- Ensure you have the Flutter SDK installed
- Clone the GitHub repo with `git clone https://github.com/SudoWatson/waste-project-app.git`
- Move into the folder with `cd waste-project-app`
- Run `flutter pub get`
- Enable Developer Options on your Android device and plug it into your computer via USB
- Run `flutter run`
The application should be installed and start on your device.

## Computer Vision Model
The app currently uses a TensorFlow model trained on the TrashNet dataset. Images taken with the app will be uploaded to a server (source coming soon) to be used to train more accurate vision models.

## Roadmap
- [ ] Publish app to Android repositories.
- [ ] Allow using the app without uploading images and feedback
- [ ] Expand common classification types
    - [ ] Batteries
    - [ ] Flexible Plastics
    - [ ] Compost
    - [ ] E-Waste
    - [ ] Etc.
- [ ] Allow users to annotate incorrectly classified images in feedback
- [ ] User accessible history/statistics
- [ ] Provide information more specific to location.

## Recycling

Today, 1 in 4 items placed in the single stream recycling bin are not recyclable, causing contamination. This kind of contamination will lead to entire trucks full of "recycling" to be redirected to landfills. Additionally, 76% of all recyclable material is thrown out at the household level, contributing to only 9% of plastics being recycled, and only about a third of all recyclable material actually getting recycled, despite this system being in use for over 60 years.

There are many other problems with the recycling system, this app is not meant to be a solution, but an assistance, and to develop a computer vision model that can be used in other ideas to help fix the system.
