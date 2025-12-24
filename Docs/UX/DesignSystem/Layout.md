# Layout & Spacing

> Defined in `lib/core/constants/editor_constants.dart` and `lib/core/constants/app_constants.dart`.

## Layout Constants

### Panels

| Component | Dimensions |
|-----------|------------|
| **Properties Panel** | Default Width: `280.0` |
| **Panel Min Width** | `200.0` |
| **Sprite List** | Default Height: `120.0` |

### Canvas & Grid

| Component | Value | Notes |
|-----------|-------|-------|
| **Grid Size** | `32.0` | Default visual grid size |
| **Zoom Levels** | `0.1x` to `10.0x` | Step size: `0.1` |

## Spacing & Dimensions

While the application uses standard Flutter padding conventions, the following specific values are defined in the theme:

**Input Fields (`AppTheme`)**
- contentPadding: `symmetric(horizontal: 12, vertical: 8)`
- borderRadius: `4.0`

**Tooltips**
- borderRadius: `4.0`
- fontSize: `12.0`

## Atlas Configuration (`AppConstants`)

The default configuration for the Atlas Packer (the core domain object):

| Setting | Default Value |
|---------|---------------|
| **Max Width** | `2048` px |
| **Max Height** | `2048` px |
| **Padding** | `2` px |
| **Format** | `png`, `json` |

## Responsive Behavior

The layout primarily uses a **Panel-based** approach typical of desktop tools:
1. **Central Canvas**: Flexible, zoomable workspace.
2. **Side Panels**: Fixed or resizable control areas (Properties, Sprite List).

The properties panel has a minimum width constraint of `200px` to ensure usability.