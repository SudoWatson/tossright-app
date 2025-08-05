# TossRight: Waste classifier and disposal instructions

`overview image go here`

# Overview
TossRight is a mobile application that is able to image waste, classify what it is, and give you instructions for the best method of disposing of that item. All images taken with the app are uploaded to a server to improve the computer vision model.

[![License: AGPL v3](https://img.shields.io/badge/License-AGPL_v3-blue.svg)](https://www.gnu.org/licenses/agpl-3.0)

## Installation
The app is in the process of being published to app repositories like F-Droid and Google Play Store. Android users can follow the **Develop** instructions to load the application. Since I don't own any Apple devices, I am unable to publish it to the Apple App Store.

## Develop
- Ensure you have the Flutter SDK installed
- Clone the GitHub repo with `git clone https://github.com/SudoWatson/waste-project-app.git`
- Move into the folder with `cd waste-project-app`
- Run `flutter pub get`
- Enable Developer Options on your Android device and plug it into your computer via USB
- Run `flutter run`
The application should be installed and start on your device.

## Computer Vision Model
The app currently uses a TensorFlow model trained on the TrashNet dataset. Images taken with the app will be uploaded to a server (source coming soon) to be used to train more accurate vision models.## Roadmap

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

## Recycling

Today, 1 in 4 items placed in the single stream recycling bin are not recyclable, causing contamination. This kind of contamination will lead to entire trucks full of "recycling" to be redirected to landfills. Additionally, 76% of all recyclable material is thrown out at the household level, contributing to only 9% of plastics being recycled, and only about a third of all recyclable material actually getting recycled, despite this system being in use for over 60 years.

There are many other problems with the recycling system, this app is not meant to be a solution, but an assistance, and to develop a computer vision model that can be used in other ideas to help fix the system.
