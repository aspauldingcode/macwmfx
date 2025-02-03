# macwmfx

![Preview](Preview.png)

# Information:
- macwmfx is a macOS tweak for ammonia injector that enables configurable WindowManager Effects to macOS, similar to what swayfx does for sway on linux. 
- Authored by [aspauldingcode](https://github.com/aspauldingcode)
- Inspired by:
  - [INTrafficLightsDisabler](https://github.com/indragiek/INTrafficLightsDisabler)
  - [StopStoplightLight](https://github.com/shishkabibal/StopStoplightLight)
  - [AfloatX](https://github.com/jslegendre/AfloatX)
  - [Goodbye](https://github.com/MacEnhance/Goodbye)

## NOTICE: this is work-in-progress. I'm working on refactoring, and I promise this product will be complete at some point. macOS users will finally have some configurable window management ricing features. For now, please sit tight. Feel free to contribute if you'd like, although prs may not be merged, until I find a repo layout I'm happy with. 

# Features:
- Configurable windowfx dotfile in ~/.config/macwmfx/config
- Disable Titlebars
- Disable Traffic Lights
- Disable Window Shadows
- Disable Window Resize Constraints (resize almost all windows to any size)
- Enable Window Blur (configure blur radius and passes)
- Enable Window Transparency
- Border Outline (active/inactive), Border Width
- **Border Corner Radius** - This one is special.
- All applications will quit when the last window closes
- Whitelist applications by bundle identifier
- Blacklist applications by bundle identifier

# Installation:
1. Download and install [ammonia](https://github.com/CoreBedtime/ammonia/releases/latest) from bedtime. Also, make sure to disable SIP, library validation, and enable preview arm64e abi.
2. Make sure you have [Nix](https://nixos.org/download) installed with flakes enabled
3. Clone the repository:
   ```bash
   git clone https://github.com/aspauldingcode/macwmfx
   cd macwmfx
   ```
4. Build and install using the flake:
   ```bash
   nix run
   ```
   This will build macwmfx and install it to `/usr/local/bin/ammonia/tweaks`

### Contributing:
Feel free to modify and adapt this code for your own projects. However, please provide appropriate attribution rather than simply rebranding it. Be respectful of the open source community. If you make improvements, we welcome pull requests and contributions back to the project.
