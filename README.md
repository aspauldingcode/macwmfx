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
- Whitelist applications by bundle identifier
- Blacklist applications by bundle identifier

# Installation (WIP):
1. Download and install [ammonia](https://github.com/CoreBedtime/ammonia/releases/latest) from bedtime. Also, make sure to disable SIP, library validation, and authenticated-root.
2. git clone [macwmfx](https://github.com/aspauldingcode/macwmfx/)
<!-- 2. Download [macwmfx](https://github.com/aspauldingcode/macwmfx/releases/latest) -->
3. Compile macwmfx with `make`
4. Install macwmfx with `make install`

### Contributing:
Feel free to modify and adapt this code for your own projects. However, please provide appropriate attribution rather than simply rebranding it. Be respectful of the open source community. If you make improvements, we welcome pull requests and contributions back to the project.
