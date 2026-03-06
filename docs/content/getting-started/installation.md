---
title: Installation
icon: fontawesome/solid/download
---

# <img src="../images/icon.png" width="20"> Installation

Before installing this plugin, make sure to uninstall any previous versions of the same plugin.

_If installing both Android and iOS versions of the plugin in the same project, then make sure that both versions use the same addon interface version._

There are 2 ways to install the OAuth2 plugin into your project:

- Through the Godot Editor's AssetLib
- Manually by downloading archives from [GitHub](https://github.com/godot-mobile-plugins/godot-oauth2/releases)

## <img src="../images/icon.png" width="18"> Installing via AssetLib

To install the OAuth2 plugin through the Godot Editor's Asset Library

- Search for and select the OAuth2 plugin in the Godot Editor

- Click the Download button

On the installation dialog:

- Keep Change Install Folder pointing to your project root

- Keep Ignore asset root checked

- Click Install

- Enable the plugin via `Project --> Project Settings… --> Plugins`

- _For iOS, also enable the plugin in the export settings._

## <img src="../images/icon.png" width="18"> Installing manually

To install the plugin manually

- Download the release archive from GitHub

- Unzip the archive

- Copy the contents into your Godot project root

- Enable the plugin via `Project --> Project Settings… --> Plugins`

- _For iOS, also enable the plugin in the export settings._

!!! note "Installing both Android and iOS versions of the plugin in the same project"
    When installing via AssetLib, the installer may warn that some files conflict.
    This is expected and can be safely ignored, as both versions share the same addon code.

## <img src="../images/icon.png" width="20"> Dependencies

**`Deeplink Plugin` version `5.3`**

The [Deeplink Plugin](https://github.com/godot-mobile-plugins/godot-deeplink) is required to receive OAuth redirect callbacks via custom URI schemes.