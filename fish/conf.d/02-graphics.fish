# ~/.config/fish/conf.d/02-graphics.fish
# Graphics, Wayland, Gaming, and AMD GPU configuration
# ============================================================================
# Graphics and Display (Wayland/X11)
# ============================================================================
set -gx MOZ_ENABLE_WAYLAND 1
set -gx XDG_SESSION_TYPE wayland
set -gx QT_QPA_PLATFORM wayland
set -gx QT_QPA_PLATFORMTHEME kde
set -gx QT_WAYLAND_DISABLE_WINDOWDECORATION 1
set -gx GDK_BACKEND wayland
set -gx SDL_VIDEODRIVER wayland
set -gx _JAVA_AWT_WM_NONREPARENTING 1
set -gx AWT_TOOLKIT "MToolkit wmname LG3D"
set -gx MOZ_USE_XINPUT2 1

# ============================================================================
# Vulkan Configuration
# ============================================================================
# XDG_RUNTIME_DIR set in 00-environment.fish

# Core AMD optimizations
set -gx RADV_PERFTEST gpl,nggc,sam
set -gx AMD_VULKAN_ICD RADV
set -gx DXVK_ASYNC 1

# ============================================================================
# Gaming and Proton Configuration
# ============================================================================
# Proton-CachyOS specific flags for AMD 6900XT
set -gx PROTON_ENABLE_HDR 1
set -gx PROTON_LOCAL_SHADER_CACHE 1
set -gx PROTON_FSR4_UPGRADE 1

# Additional performance flags
set -gx PROTON_USE_NTSYNC 1
set -gx PROTON_ENABLE_WAYLAND 1

# Steam configuration
set -gx STEAM_COMPAT_CLIENT_INSTALL_PATH $HOME/.steam
set -gx STEAM_COMPAT_DATA_PATH $HOME/.steam/steam/steamapps/compatdata

# ============================================================================
# AI/Gaming Related (ROCM & Gaming)
# ============================================================================
# gfx1200 architecture (RX 9070 XT) - native support with gfx120X PyTorch wheels
# HSA_OVERRIDE_GFX_VERSION not needed with native wheels, but harmless as a fallback
set -gx HSA_OVERRIDE_GFX_VERSION 12.0.0
if not contains /opt/rocm/lib $LD_LIBRARY_PATH
    set -gx LD_LIBRARY_PATH $LD_LIBRARY_PATH /opt/rocm/lib
end

# ROCm/PyTorch performance and stability optimizations
set -gx PYTORCH_HIP_ALLOC_CONF garbage_collection_threshold:0.8,max_split_size_mb:2048
set -gx HSA_ENABLE_SDMA 0
set -gx GPU_MAX_HEAP_SIZE 100
set -gx GPU_MAX_ALLOC_PERCENT 100

set -gx MESA_VK_WSI_PRESENT_MODE fifo

# Video acceleration
set -gx VDPAU_DRIVER radeonsi
set -gx LIBVA_DRIVER_NAME radeonsi

# ============================================================================
# GPU Threading and Cache Optimizations
# ============================================================================
set -gx MESA_GLTHREAD true
set -gx MESA_NO_ERROR 1
# Removed __GL_* vars — NVIDIA-specific, not applicable to AMD RADV

# Performance and Compatibility
set -gx ELECTRON_OZONE_PLATFORM_HINT auto
set -gx _JAVA_OPTIONS '-Dawt.useSystemAAFontSettings=on -Dswing.aatext=true'
