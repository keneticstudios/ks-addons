// ============================================================
// CONFIGURATION - Edit these values to customize the inventory
// ============================================================

window.Config = {
    colors: {
        // Primary Accent - Deep blue with good contrast
        accent: "#4a90d9",
        accentHover: "#3a7ac4",

        // Container/Background - Clean dark tones
        background: "rgba(12, 12, 16, 0.95)",
        bgGradient: "radial-gradient(ellipse at center, rgba(8, 8, 12, 0.2) 0%, rgba(0, 0, 0, 0.85) 100%)",

        // Slot Colors - Subtle and professional
        slotBackground: "rgba(24, 24, 30, 0.7)",
        slotBackgroundHover: "rgba(40, 40, 50, 0.85)",
        slotBorder: "rgba(255, 255, 255, 0.06)",

        // Text Colors
        textMain: "#f0f0f2",
        textSecondary: "rgba(255, 255, 255, 0.6)",

        // Border Colors
        borderColor: "rgba(255, 255, 255, 0.08)",

        // Status Colors - Refined
        success: "#3cba6d",
        danger: "#e54d4d",
        warning: "#e8a030"
    },
    rotationAngle: 2,
    character: {
        showPed: true
    },
    clothing: {
        enabled: true,
        asButtons: false  // ← Set to true
    }
};

console.log('[Config] Loaded:', window.Config);
