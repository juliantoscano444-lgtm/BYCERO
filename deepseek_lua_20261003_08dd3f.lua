-- ============================================
-- FREECAM v36 - CINEMÁTICAS CON VELOCIDAD AJUSTABLE
-- La barrita de velocidad controla las tomas
-- ============================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local StarterGui = game:GetService("StarterGui")
local Lighting = game:GetService("Lighting")
local CaptureService = game:GetService("CaptureService")

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera

-- ============ CONFIGURACIÓN ============
local activo = false
local velocidad = 60
local sensibilidad = 0.5
local subiendo = false
local bajando = false
local yaw = 0
local pitch = 0
local limitePitch = math.rad(89)
local posicionCamara = Vector3.zero

local cineActivo = false
local cineConexion = nil
local cineTomaActual = 0
local cinePersonaje = nil
local cineAngulo = 0
local cineSuavizado = nil

-- ============ 16 TOMAS CINEMÁTICAS ============
local TOMAS = {
    {nombre = "Órbita Clásica", radio = 14, altura = 3, velocidadGiro = 0.4, fov = 70, inclinacion = 0},
    {nombre = "Giro Rápido", radio = 18, altura = 5, velocidadGiro = 1.2, fov = 80, inclinacion = 0},
    {nombre = "Vista Aérea", radio = 20, altura = 22, velocidadGiro = 0.6, fov = 60, inclinacion = -0.5},
    {nombre = "Primer Plano", radio = 5, altura = 1.5, velocidadGiro = 0.8, fov = 45, inclinacion = 0},
    {nombre = "Órbita Lejana", radio = 35, altura = 8, velocidadGiro = 0.3, fov = 90, inclinacion = 0.2},
    {nombre = "Giro Inclinado", radio = 15, altura = 6, velocidadGiro = 0.7, fov = 65, inclinacion = 0.4},
    {nombre = "Contra-Picado", radio = 12, altura = -1, velocidadGiro = 0.5, fov = 75, inclinacion = -0.3},
    {nombre = "Vuelta Épica", radio = 25, altura = 12, velocidadGiro = 1.0, fov = 100, inclinacion = 0.1},
    {nombre = "Dron Aéreo", radio = 30, altura = 35, velocidadGiro = 0.8, fov = 55, inclinacion = -0.7},
    {nombre = "Rasante Suelo", radio = 10, altura = 0.3, velocidadGiro = 1.5, fov = 80, inclinacion = 0.1},
    {nombre = "Espiral Subida", radio = 12, altura = 2, velocidadGiro = 0.6, fov = 70, inclinacion = 0.2, espiral = 15},
    {nombre = "Espiral Bajada", radio = 25, altura = 20, velocidadGiro = 0.5, fov = 75, inclinacion = -0.3, espiral = -12},
    {nombre = "Cenital Perfecto", radio = 18, altura = 40, velocidadGiro = 0.3, fov = 50, inclinacion = -1.5},
    {nombre = "Contrapicado Épico", radio = 10, altura = -3, velocidadGiro = 0.9, fov = 85, inclinacion = -0.5},
    {nombre = "Zoom In Lejano", radio = 45, altura = 10, velocidadGiro = 0.2, fov = 40, inclinacion = 0.15, acercarse = true},
    {nombre = "Vuelta Completa", radio = 22, altura = 8, velocidadGiro = 2.0, fov = 90, inclinacion = 0.3}
}

-- ============ 12 GRÁFICOS ============
local GRAFICOS = {
    {nombre = "Daytime", Ambient = Color3.fromRGB(70,70,70), Brightness = 2, OutdoorAmbient = Color3.fromRGB(128,128,128), ClockTime = 14, FogColor = Color3.fromRGB(192,192,192), FogEnd = 100000, FogStart = 0, ColorShift_Top = Color3.fromRGB(0,0,0), ColorShift_Bottom = Color3.fromRGB(0,0,0), EnvironmentDiffuseScale = 0.5, EnvironmentSpecularScale = 0.5, GlobalShadows = true, AtmosDensity = 0.3, AtmosHaze = 1.5, AtmosGlare = 0.1, AtmosColor = Color3.fromRGB(199,199,199), AtmosDecay = Color3.fromRGB(106,112,125), BloomIntensity = 0.5, BloomSize = 24, BloomThreshold = 0.9, CCBrightness = 0, CCContrast = 0, CCSaturation = 0, CCTint = Color3.fromRGB(255,255,255), SunRaysIntensity = 0.1, SunRaysSpread = 1, CloudsCover = 0.5, CloudsDensity = 0.5, CloudsColor = Color3.fromRGB(255,255,255)},
    {nombre = "Golden", Ambient = Color3.fromRGB(120,80,50), Brightness = 2.2, OutdoorAmbient = Color3.fromRGB(180,130,80), ClockTime = 17, FogColor = Color3.fromRGB(255,180,100), FogEnd = 700, FogStart = 0, ColorShift_Top = Color3.fromRGB(255,180,80), ColorShift_Bottom = Color3.fromRGB(120,50,20), EnvironmentDiffuseScale = 0.8, EnvironmentSpecularScale = 0.6, GlobalShadows = true, AtmosDensity = 0.4, AtmosHaze = 2.5, AtmosGlare = 0.5, AtmosColor = Color3.fromRGB(255,190,120), AtmosDecay = Color3.fromRGB(200,120,60), BloomIntensity = 1.2, BloomSize = 32, BloomThreshold = 0.8, CCBrightness = 0.05, CCContrast = 0.1, CCSaturation = 0.2, CCTint = Color3.fromRGB(255,220,180), SunRaysIntensity = 0.4, SunRaysSpread = 1.2, CloudsCover = 0.4, CloudsDensity = 0.5, CloudsColor = Color3.fromRGB(255,200,150)},
    {nombre = "Sunset", Ambient = Color3.fromRGB(85,60,45), Brightness = 1.5, OutdoorAmbient = Color3.fromRGB(140,90,60), ClockTime = 18, FogColor = Color3.fromRGB(220,140,90), FogEnd = 800, FogStart = 0, ColorShift_Top = Color3.fromRGB(255,140,60), ColorShift_Bottom = Color3.fromRGB(80,30,10), EnvironmentDiffuseScale = 0.6, EnvironmentSpecularScale = 0.4, GlobalShadows = true, AtmosDensity = 0.5, AtmosHaze = 3, AtmosGlare = 0.7, AtmosColor = Color3.fromRGB(255,150,90), AtmosDecay = Color3.fromRGB(180,80,40), BloomIntensity = 1.5, BloomSize = 40, BloomThreshold = 0.7, CCBrightness = 0, CCContrast = 0.15, CCSaturation = 0.3, CCTint = Color3.fromRGB(255,180,140), SunRaysIntensity = 0.6, SunRaysSpread = 1.5, CloudsCover = 0.6, CloudsDensity = 0.6, CloudsColor = Color3.fromRGB(255,170,120)},
    {nombre = "Twilight", Ambient = Color3.fromRGB(40,30,60), Brightness = 1.2, OutdoorAmbient = Color3.fromRGB(70,50,100), ClockTime = 19, FogColor = Color3.fromRGB(80,50,120), FogEnd = 600, FogStart = 0, ColorShift_Top = Color3.fromRGB(150,80,180), ColorShift_Bottom = Color3.fromRGB(30,10,50), EnvironmentDiffuseScale = 0.7, EnvironmentSpecularScale = 0.4, GlobalShadows = true, AtmosDensity = 0.5, AtmosHaze = 2.5, AtmosGlare = 0.3, AtmosColor = Color3.fromRGB(120,80,160), AtmosDecay = Color3.fromRGB(60,30,90), BloomIntensity = 1.0, BloomSize = 32, BloomThreshold = 0.75, CCBrightness = -0.05, CCContrast = 0.1, CCSaturation = 0.25, CCTint = Color3.fromRGB(200,160,255), SunRaysIntensity = 0.3, SunRaysSpread = 1, CloudsCover = 0.5, CloudsDensity = 0.5, CloudsColor = Color3.fromRGB(150,120,180)},
    {nombre = "Night", Ambient = Color3.fromRGB(15,15,25), Brightness = 0.5, OutdoorAmbient = Color3.fromRGB(30,30,50), ClockTime = 0, FogColor = Color3.fromRGB(15,15,30), FogEnd = 500, FogStart = 0, ColorShift_Top = Color3.fromRGB(20,20,60), ColorShift_Bottom = Color3.fromRGB(5,5,15), EnvironmentDiffuseScale = 0.3, EnvironmentSpecularScale = 0.3, GlobalShadows = true, AtmosDensity = 0.4, AtmosHaze = 1.5, AtmosGlare = 0, AtmosColor = Color3.fromRGB(30,30,60), AtmosDecay = Color3.fromRGB(10,10,30), BloomIntensity = 0.6, BloomSize = 20, BloomThreshold = 0.85, CCBrightness = -0.1, CCContrast = 0.15, CCSaturation = -0.1, CCTint = Color3.fromRGB(150,160,220), SunRaysIntensity = 0, SunRaysSpread = 1, CloudsCover = 0.4, CloudsDensity = 0.5, CloudsColor = Color3.fromRGB(40,40,70)},
    {nombre = "Midnight", Ambient = Color3.fromRGB(5,5,15), Brightness = 0.3, OutdoorAmbient = Color3.fromRGB(15,15,30), ClockTime = 2, FogColor = Color3.fromRGB(5,5,15), FogEnd = 300, FogStart = 0, ColorShift_Top = Color3.fromRGB(10,10,40), ColorShift_Bottom = Color3.fromRGB(0,0,5), EnvironmentDiffuseScale = 0.2, EnvironmentSpecularScale = 0.2, GlobalShadows = true, AtmosDensity = 0.5, AtmosHaze = 2, AtmosGlare = 0, AtmosColor = Color3.fromRGB(10,10,30), AtmosDecay = Color3.fromRGB(5,5,15), BloomIntensity = 0.4, BloomSize = 16, BloomThreshold = 0.9, CCBrightness = -0.15, CCContrast = 0.2, CCSaturation = -0.2, CCTint = Color3.fromRGB(80,90,150), SunRaysIntensity = 0, SunRaysSpread = 1, CloudsCover = 0.3, CloudsDensity = 0.4, CloudsColor = Color3.fromRGB(20,20,50)},
    {nombre = "Cloudy", Ambient = Color3.fromRGB(90,90,95), Brightness = 1, OutdoorAmbient = Color3.fromRGB(120,120,125), ClockTime = 12, FogColor = Color3.fromRGB(150,150,160), FogEnd = 400, FogStart = 0, ColorShift_Top = Color3.fromRGB(0,0,0), ColorShift_Bottom = Color3.fromRGB(0,0,0), EnvironmentDiffuseScale = 0.4, EnvironmentSpecularScale = 0.3, GlobalShadows = false, AtmosDensity = 0.6, AtmosHaze = 3, AtmosGlare = 0, AtmosColor = Color3.fromRGB(150,150,160), AtmosDecay = Color3.fromRGB(100,100,110), BloomIntensity = 0.3, BloomSize = 16, BloomThreshold = 1, CCBrightness = -0.05, CCContrast = 0.05, CCSaturation = -0.2, CCTint = Color3.fromRGB(200,200,210), SunRaysIntensity = 0, SunRaysSpread = 1, CloudsCover = 1, CloudsDensity = 0.9, CloudsColor = Color3.fromRGB(180,180,190)},
    {nombre = "Stormy", Ambient = Color3.fromRGB(30,30,40), Brightness = 0.8, OutdoorAmbient = Color3.fromRGB(50,50,70), ClockTime = 15, FogColor = Color3.fromRGB(60,60,75), FogEnd = 250, FogStart = 0, ColorShift_Top = Color3.fromRGB(40,40,60), ColorShift_Bottom = Color3.fromRGB(10,10,20), EnvironmentDiffuseScale = 0.3, EnvironmentSpecularScale = 0.4, GlobalShadows = true, AtmosDensity = 0.8, AtmosHaze = 4, AtmosGlare = 0, AtmosColor = Color3.fromRGB(60,60,80), AtmosDecay = Color3.fromRGB(30,30,50), BloomIntensity = 0.4, BloomSize = 24, BloomThreshold = 0.9, CCBrightness = -0.1, CCContrast = 0.15, CCSaturation = -0.15, CCTint = Color3.fromRGB(150,160,180), SunRaysIntensity = 0, SunRaysSpread = 1, CloudsCover = 1, CloudsDensity = 0.95, CloudsColor = Color3.fromRGB(60,65,80)},
    {nombre = "Shore", Ambient = Color3.fromRGB(100,130,150), Brightness = 2.5, OutdoorAmbient = Color3.fromRGB(150,180,200), ClockTime = 13, FogColor = Color3.fromRGB(180,210,230), FogEnd = 1200, FogStart = 0, ColorShift_Top = Color3.fromRGB(50,100,130), ColorShift_Bottom = Color3.fromRGB(20,40,60), EnvironmentDiffuseScale = 0.7, EnvironmentSpecularScale = 0.6, GlobalShadows = true, AtmosDensity = 0.3, AtmosHaze = 1, AtmosGlare = 0.3, AtmosColor = Color3.fromRGB(180,210,240), AtmosDecay = Color3.fromRGB(100,140,180), BloomIntensity = 0.8, BloomSize = 24, BloomThreshold = 0.85, CCBrightness = 0.05, CCContrast = 0.05, CCSaturation = 0.15, CCTint = Color3.fromRGB(200,230,255), SunRaysIntensity = 0.2, SunRaysSpread = 1, CloudsCover = 0.3, CloudsDensity = 0.4, CloudsColor = Color3.fromRGB(220,240,255)},
    {nombre = "Cyberpunk", Ambient = Color3.fromRGB(60,20,90), Brightness = 1.5, OutdoorAmbient = Color3.fromRGB(100,50,150), ClockTime = 20, FogColor = Color3.fromRGB(120,30,180), FogEnd = 500, FogStart = 0, ColorShift_Top = Color3.fromRGB(255,0,200), ColorShift_Bottom = Color3.fromRGB(0,50,255), EnvironmentDiffuseScale = 1, EnvironmentSpecularScale = 0.8, GlobalShadows = true, AtmosDensity = 0.7, AtmosHaze = 3, AtmosGlare = 0.8, AtmosColor = Color3.fromRGB(200,50,255), AtmosDecay = Color3.fromRGB(80,20,150), BloomIntensity = 2, BloomSize = 50, BloomThreshold = 0.5, CCBrightness = 0.05, CCContrast = 0.3, CCSaturation = 0.5, CCTint = Color3.fromRGB(255,150,255), SunRaysIntensity = 0.3, SunRaysSpread = 2, CloudsCover = 0.6, CloudsDensity = 0.6, CloudsColor = Color3.fromRGB(200,50,255)},
    {nombre = "Winter", Ambient = Color3.fromRGB(150,160,180), Brightness = 2.2, OutdoorAmbient = Color3.fromRGB(200,210,230), ClockTime = 12, FogColor = Color3.fromRGB(220,230,250), FogEnd = 600, FogStart = 0, ColorShift_Top = Color3.fromRGB(180,200,230), ColorShift_Bottom = Color3.fromRGB(100,120,150), EnvironmentDiffuseScale = 0.9, EnvironmentSpecularScale = 0.7, GlobalShadows = true, AtmosDensity = 0.4, AtmosHaze = 2, AtmosGlare = 0.2, AtmosColor = Color3.fromRGB(220,235,255), AtmosDecay = Color3.fromRGB(150,180,210), BloomIntensity = 0.9, BloomSize = 32, BloomThreshold = 0.8, CCBrightness = 0.05, CCContrast = 0.05, CCSaturation = -0.1, CCTint = Color3.fromRGB(220,240,255), SunRaysIntensity = 0.2, SunRaysSpread = 1, CloudsCover = 0.7, CloudsDensity = 0.7, CloudsColor = Color3.fromRGB(240,245,255)},
    {nombre = "Default (Original)", esDefault = true}
}

-- Guardar estado original
local luzOriginal = {
    Ambient = Lighting.Ambient, Brightness = Lighting.Brightness,
    OutdoorAmbient = Lighting.OutdoorAmbient, ClockTime = Lighting.ClockTime,
    FogColor = Lighting.FogColor, FogEnd = Lighting.FogEnd, FogStart = Lighting.FogStart,
    ColorShift_Top = Lighting.ColorShift_Top, ColorShift_Bottom = Lighting.ColorShift_Bottom,
    EnvironmentDiffuseScale = Lighting.EnvironmentDiffuseScale,
    EnvironmentSpecularScale = Lighting.EnvironmentSpecularScale,
    GlobalShadows = Lighting.GlobalShadows
}

local function obtenerDeLighting(clase)
    for _, obj in pairs(Lighting:GetChildren()) do
        if obj:IsA(clase) then return obj end
    end
    return nil
end

local function obtenerDeWorkspace(clase)
    for _, obj in pairs(Workspace:GetChildren()) do
        if obj:IsA(clase) then return obj end
    end
    return nil
end

local skyOriginal = obtenerDeLighting("Sky")
local atmosOriginal = obtenerDeLighting("Atmosphere")
local bloomOriginal = obtenerDeLighting("BloomEffect")
local ccOriginal = obtenerDeLighting("ColorCorrectionEffect")
local srOriginal = obtenerDeLighting("SunRaysEffect")
local cloudsOriginal = obtenerDeWorkspace("Clouds")

local skyNuevo, atmosNuevo, bloomNuevo, ccNuevo, srNuevo, cloudsNuevo

local graficoActual = 0

local camaraOriginal = camera.CameraType
local sujetoOriginal = camera.CameraSubject
local cframeOriginal = camera.CFrame
local fovOriginal = camera.FieldOfView
local walkspeedOriginal = 16
local jumppowerOriginal = 50

local modoLimpioActivo = false
local personajeOculto = false
local partesOriginales = {}
local estadoOriginal = {}

pcall(function() StarterGui:SetCore("TopbarEnabled", false) end)

-- ============ INTERFAZ ============
local gui = Instance.new("ScreenGui")
gui.Name = "FreecamUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 9999
gui.Parent = player:WaitForChild("PlayerGui")

local btnActivar = Instance.new("TextButton")
btnActivar.Size = UDim2.new(0, 80, 0, 32)
btnActivar.Position = UDim2.new(0, 12, 0.5, -16)
btnActivar.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
btnActivar.Text = "🎥 Freecam"
btnActivar.TextColor3 = Color3.fromRGB(255, 255, 255)
btnActivar.TextSize = 11
btnActivar.Font = Enum.Font.GothamBold
btnActivar.BorderSizePixel = 0
btnActivar.Active = true
btnActivar.Parent = gui

local cBtn = Instance.new("UICorner")
cBtn.CornerRadius = UDim.new(1, 0)
cBtn.Parent = btnActivar

do
    local arrastrando = false
    local inicio = nil
    local posInicial = nil

    btnActivar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            arrastrando = true
            inicio = input.Position
            posInicial = btnActivar.Position
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if not arrastrando then return end
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - inicio
            if delta.Magnitude > 10 then
                btnActivar.Position = UDim2.new(
                    posInicial.X.Scale, posInicial.X.Offset + delta.X,
                    posInicial.Y.Scale, posInicial.Y.Offset + delta.Y
                )
            end
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            arrastrando = false
        end
    end)
end

local controles = Instance.new("Frame")
controles.Size = UDim2.new(1, 0, 1, 0)
controles.BackgroundTransparency = 1
controles.Visible = false
controles.Parent = gui

local barra = Instance.new("Frame")
barra.Size = UDim2.new(0, 480, 0, 36)
barra.Position = UDim2.new(0.5, -240, 0.12, 0)
barra.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
barra.BackgroundTransparency = 0.1
barra.BorderSizePixel = 0
barra.Parent = controles

local cBarra = Instance.new("UICorner")
cBarra.CornerRadius = UDim.new(1, 0)
cBarra.Parent = barra

local btnCerrar = Instance.new("TextButton")
btnCerrar.Size = UDim2.new(0, 60, 0, 26)
btnCerrar.Position = UDim2.new(0, 8, 0.5, -13)
btnCerrar.BackgroundColor3 = Color3.fromRGB(230, 70, 70)
btnCerrar.Text = "Cerrar"
btnCerrar.TextColor3 = Color3.fromRGB(255, 255, 255)
btnCerrar.TextSize = 11
btnCerrar.Font = Enum.Font.GothamBold
btnCerrar.BorderSizePixel = 0
btnCerrar.Parent = barra

local cCerrar = Instance.new("UICorner")
cCerrar.CornerRadius = UDim.new(1, 0)
cCerrar.Parent = btnCerrar

local btnLimpio = Instance.new("TextButton")
btnLimpio.Size = UDim2.new(0, 80, 0, 26)
btnLimpio.Position = UDim2.new(0, 72, 0.5, -13)
btnLimpio.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
btnLimpio.Text = "Modo limpio"
btnLimpio.TextColor3 = Color3.fromRGB(255, 255, 255)
btnLimpio.TextSize = 10
btnLimpio.Font = Enum.Font.Gotham
btnLimpio.BorderSizePixel = 0
btnLimpio.Parent = barra

local cLimpio = Instance.new("UICorner")
cLimpio.CornerRadius = UDim.new(1, 0)
cLimpio.Parent = btnLimpio

local btnOcultar = Instance.new("TextButton")
btnOcultar.Size = UDim2.new(0, 75, 0, 26)
btnOcultar.Position = UDim2.new(0, 156, 0.5, -13)
btnOcultar.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
btnOcultar.Text = "Ocultarme"
btnOcultar.TextColor3 = Color3.fromRGB(255, 255, 255)
btnOcultar.TextSize = 10
btnOcultar.Font = Enum.Font.Gotham
btnOcultar.BorderSizePixel = 0
btnOcultar.Parent = barra

local cOcultar = Instance.new("UICorner")
cOcultar.CornerRadius = UDim.new(1, 0)
cOcultar.Parent = btnOcultar

local btnCine = Instance.new("TextButton")
btnCine.Size = UDim2.new(0, 65, 0, 26)
btnCine.Position = UDim2.new(0, 235, 0.5, -13)
btnCine.BackgroundColor3 = Color3.fromRGB(150, 50, 200)
btnCine.Text = "🎬 Cine"
btnCine.TextColor3 = Color3.fromRGB(255, 255, 255)
btnCine.TextSize = 10
btnCine.Font = Enum.Font.GothamBold
btnCine.BorderSizePixel = 0
btnCine.Parent = barra

local cCine = Instance.new("UICorner")
cCine.CornerRadius = UDim.new(1, 0)
cCine.Parent = btnCine

local btnGraficos = Instance.new("TextButton")
btnGraficos.Size = UDim2.new(0, 85, 0, 26)
btnGraficos.Position = UDim2.new(0, 305, 0.5, -13)
btnGraficos.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
btnGraficos.Text = "🎨 Gráficos"
btnGraficos.TextColor3 = Color3.fromRGB(255, 255, 255)
btnGraficos.TextSize = 10
btnGraficos.Font = Enum.Font.Gotham
btnGraficos.BorderSizePixel = 0
btnGraficos.Parent = barra

local cGraficos = Instance.new("UICorner")
cGraficos.CornerRadius = UDim.new(1, 0)
cGraficos.Parent = btnGraficos

local labelVel = Instance.new("TextLabel")
labelVel.Size = UDim2.new(0, 70, 0, 11)
labelVel.Position = UDim2.new(0, 400, 0, 1)
labelVel.BackgroundTransparency = 1
labelVel.Text = "Vel " .. velocidad
labelVel.TextColor3 = Color3.fromRGB(200, 200, 200)
labelVel.TextSize = 9
labelVel.Font = Enum.Font.Gotham
labelVel.Parent = barra

local sliderFondo = Instance.new("Frame")
sliderFondo.Size = UDim2.new(0, 70, 0, 12)
sliderFondo.Position = UDim2.new(0, 400, 0, 17)
sliderFondo.BackgroundColor3 = Color3.fromRGB(60, 60, 65)
sliderFondo.BorderSizePixel = 0
sliderFondo.Parent = barra

local cSld = Instance.new("UICorner")
cSld.CornerRadius = UDim.new(1, 0)
cSld.Parent = sliderFondo

local sliderRelleno = Instance.new("Frame")
sliderRelleno.Size = UDim2.new(0.18, 0, 1, 0)
sliderRelleno.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
sliderRelleno.BorderSizePixel = 0
sliderRelleno.Parent = sliderFondo

local cRell = Instance.new("UICorner")
cRell.CornerRadius = UDim.new(1, 0)
cRell.Parent = sliderRelleno

local joyFondo = Instance.new("Frame")
joyFondo.Size = UDim2.new(0, 100, 0, 100)
joyFondo.Position = UDim2.new(0, 20, 1, -125)
joyFondo.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
joyFondo.BackgroundTransparency = 0.85
joyFondo.BorderSizePixel = 0
joyFondo.Active = true
joyFondo.Parent = controles

local cJoy = Instance.new("UICorner")
cJoy.CornerRadius = UDim.new(1, 0)
cJoy.Parent = joyFondo

local joyBola = Instance.new("Frame")
joyBola.Size = UDim2.new(0, 42, 0, 42)
joyBola.Position = UDim2.new(0.5, -21, 0.5, -21)
joyBola.BackgroundColor3 = Color3.fromRGB(220, 220, 220)
joyBola.BackgroundTransparency = 0.1
joyBola.BorderSizePixel = 0
joyBola.Parent = joyFondo

local cBola = Instance.new("UICorner")
cBola.CornerRadius = UDim.new(1, 0)
cBola.Parent = joyBola

local btnSubir = Instance.new("TextButton")
btnSubir.Size = UDim2.new(0, 45, 0, 45)
btnSubir.Position = UDim2.new(1, -70, 1, -155)
btnSubir.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
btnSubir.BackgroundTransparency = 0.85
btnSubir.Text = "▲"
btnSubir.TextColor3 = Color3.fromRGB(255, 255, 255)
btnSubir.TextSize = 22
btnSubir.Font = Enum.Font.GothamBold
btnSubir.BorderSizePixel = 0
btnSubir.Active = true
btnSubir.Parent = controles

local cSub = Instance.new("UICorner")
cSub.CornerRadius = UDim.new(1, 0)
cSub.Parent = btnSubir

local btnBajar = Instance.new("TextButton")
btnBajar.Size = UDim2.new(0, 45, 0, 45)
btnBajar.Position = UDim2.new(1, -70, 1, -105)
btnBajar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
btnBajar.BackgroundTransparency = 0.85
btnBajar.Text = "▼"
btnBajar.TextColor3 = Color3.fromRGB(255, 255, 255)
btnBajar.TextSize = 22
btnBajar.Font = Enum.Font.GothamBold
btnBajar.BorderSizePixel = 0
btnBajar.Active = true
btnBajar.Parent = controles

local cBaj = Instance.new("UICorner")
cBaj.CornerRadius = UDim.new(1, 0)
cBaj.Parent = btnBajar

local btnX = Instance.new("TextButton")
btnX.Size = UDim2.new(0, 40, 0, 40)
btnX.Position = UDim2.new(1, -55, 0, 15)
btnX.BackgroundColor3 = Color3.fromRGB(230, 70, 70)
btnX.BackgroundTransparency = 0.15
btnX.Text = "✕"
btnX.TextColor3 = Color3.fromRGB(255, 255, 255)
btnX.TextSize = 18
btnX.Font = Enum.Font.GothamBold
btnX.BorderSizePixel = 0
btnX.Active = true
btnX.Visible = false
btnX.Parent = gui

local cX = Instance.new("UICorner")
cX.CornerRadius = UDim.new(1, 0)
cX.Parent = btnX

-- ============ FUNCIONES ============
local function congelarPersonaje()
    local char = player.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            walkspeedOriginal = hum.WalkSpeed
            jumppowerOriginal = hum.JumpPower
            hum.WalkSpeed = 0
            hum.JumpPower = 0
        end
        local root = char:FindFirstChild("HumanoidRootPart")
        if root then root.Anchored = true end
    end
end

local function descongelarPersonaje()
    local char = player.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.WalkSpeed = walkspeedOriginal
            hum.JumpPower = jumppowerOriginal
        end
        local root = char:FindFirstChild("HumanoidRootPart")
        if root then root.Anchored = false end
    end
end

local function ocultarPersonaje()
    local char = player.Character
    if not char then return end
    partesOriginales = {}
    for _, parte in pairs(char:GetDescendants()) do
        if parte:IsA("BasePart") then
            partesOriginales[parte] = {
                Transparency = parte.Transparency,
                LocalTransparencyModifier = parte.LocalTransparencyModifier
            }
            parte.Transparency = 1
            parte.LocalTransparencyModifier = 1
        elseif parte:IsA("Decal") then
            partesOriginales[parte] = { Transparency = parte.Transparency }
            parte.Transparency = 1
        end
    end
end

local function mostrarPersonaje()
    for parte, datos in pairs(partesOriginales) do
        if parte and parte.Parent then
            if datos.Transparency ~= nil then parte.Transparency = datos.Transparency end
            if datos.LocalTransparencyModifier ~= nil then parte.LocalTransparencyModifier = datos.LocalTransparencyModifier end
        end
    end
    partesOriginales = {}
end

-- ============ MODO LIMPIO ============
local function recolectarTodosLosGui(container, lista)
    for _, v in pairs(container:GetChildren()) do
        if v:IsA("ScreenGui") and v.Name ~= "FreecamUI" then
            table.insert(lista, v)
        end
        pcall(function()
            recolectarTodosLosGui(v, lista)
        end)
    end
end

local function activarModoLimpio()
    modoLimpioActivo = true
    estadoOriginal = {}
    
    local listaGuis = {}
    pcall(function() recolectarTodosLosGui(CoreGui, listaGuis) end)
    pcall(function() recolectarTodosLosGui(player:WaitForChild("PlayerGui"), listaGuis) end)
    
    for _, screenGui in pairs(listaGuis) do
        for _, hijo in pairs(screenGui:GetDescendants()) do
            if hijo:IsA("GuiObject") then
                estadoOriginal[hijo] = {
                    BackgroundTransparency = hijo.BackgroundTransparency,
                    Visible = hijo.Visible,
                    TextTransparency = (hijo:IsA("TextLabel") or hijo:IsA("TextButton") or hijo:IsA("TextBox")) and hijo.TextTransparency or nil,
                    TextStrokeTransparency = (hijo:IsA("TextLabel") or hijo:IsA("TextButton") or hijo:IsA("TextBox")) and hijo.TextStrokeTransparency or nil,
                    ImageTransparency = (hijo:IsA("ImageLabel") or hijo:IsA("ImageButton")) and hijo.ImageTransparency or nil
                }
                
                hijo.BackgroundTransparency = 1
                if hijo:IsA("TextLabel") or hijo:IsA("TextButton") or hijo:IsA("TextBox") then
                    hijo.TextTransparency = 1
                    hijo.TextStrokeTransparency = 1
                end
                if hijo:IsA("ImageLabel") or hijo:IsA("ImageButton") then
                    hijo.ImageTransparency = 1
                end
                
                for _, efecto in pairs(hijo:GetChildren()) do
                    if efecto:IsA("UIStroke") then
                        estadoOriginal[efecto] = { Transparency = efecto.Transparency }
                        efecto.Transparency = 1
                    end
                end
            end
        end
    end
    
    controles.Visible = false
    btnX.Visible = true
end

local function desactivarModoLimpio()
    modoLimpioActivo = false
    
    for elemento, datos in pairs(estadoOriginal) do
        if elemento and elemento.Parent then
            if datos.BackgroundTransparency ~= nil then elemento.BackgroundTransparency = datos.BackgroundTransparency end
            if datos.Visible ~= nil then elemento.Visible = datos.Visible end
            if datos.TextTransparency ~= nil then elemento.TextTransparency = datos.TextTransparency end
            if datos.TextStrokeTransparency ~= nil then elemento.TextStrokeTransparency = datos.TextStrokeTransparency end
            if datos.ImageTransparency ~= nil then elemento.ImageTransparency = datos.ImageTransparency end
            if datos.Transparency ~= nil then elemento.Transparency = datos.Transparency end
        end
    end
    
    estadoOriginal = {}
    controles.Visible = true
    btnX.Visible = false
end

-- ============ GRÁFICOS ============
local function aplicarSkybox(graf)
    if skyNuevo then skyNuevo:Destroy(); skyNuevo = nil end
    if graf.esDefault then
        if skyOriginal then skyOriginal.Parent = Lighting end
        return
    end
    if graf.SkyboxBk then
        local sky = Instance.new("Sky")
        sky.SkyboxBk = graf.SkyboxBk
        sky.SkyboxDn = graf.SkyboxDn
        sky.SkyboxFt = graf.SkyboxFt
        sky.SkyboxLf = graf.SkyboxLf
        sky.SkyboxRt = graf.SkyboxRt
        sky.SkyboxUp = graf.SkyboxUp
        sky.Parent = Lighting
        skyNuevo = sky
        if skyOriginal then skyOriginal.Parent = nil end
    end
end

local function aplicarAtmosphere(graf)
    if atmosNuevo then atmosNuevo:Destroy(); atmosNuevo = nil end
    if graf.esDefault then
        if atmosOriginal then atmosOriginal.Parent = Lighting end
        return
    end
    if graf.AtmosDensity then
        local atmos = Instance.new("Atmosphere")
        atmos.Density = graf.AtmosDensity
        atmos.Haze = graf.AtmosHaze
        atmos.Glare = graf.AtmosGlare
        atmos.Color = graf.AtmosColor
        atmos.Decay = graf.AtmosDecay
        atmos.Parent = Lighting
        atmosNuevo = atmos
        if atmosOriginal then atmosOriginal.Parent = nil end
    end
end

local function aplicarBloom(graf)
    if bloomNuevo then bloomNuevo:Destroy(); bloomNuevo = nil end
    if graf.esDefault then
        if bloomOriginal then bloomOriginal.Parent = Lighting end
        return
    end
    if graf.BloomIntensity then
        local bloom = Instance.new("BloomEffect")
        bloom.Intensity = graf.BloomIntensity
        bloom.Size = graf.BloomSize
        bloom.Threshold = graf.BloomThreshold
        bloom.Parent = Lighting
        bloomNuevo = bloom
        if bloomOriginal then bloomOriginal.Parent = nil end
    end
end

local function aplicarColorCorrection(graf)
    if ccNuevo then ccNuevo:Destroy(); ccNuevo = nil end
    if graf.esDefault then
        if ccOriginal then ccOriginal.Parent = Lighting end
        return
    end
    if graf.CCBrightness then
        local cc = Instance.new("ColorCorrectionEffect")
        cc.Brightness = graf.CCBrightness
        cc.Contrast = graf.CCContrast
        cc.Saturation = graf.CCSaturation
        cc.TintColor = graf.CCTint
        cc.Parent = Lighting
        ccNuevo = cc
        if ccOriginal then ccOriginal.Parent = nil end
    end
end

local function aplicarSunRays(graf)
    if srNuevo then srNuevo:Destroy(); srNuevo = nil end
    if graf.esDefault then
        if srOriginal then srOriginal.Parent = Lighting end
        return
    end
    if graf.SunRaysIntensity then
        local sr = Instance.new("SunRaysEffect")
        sr.Intensity = graf.SunRaysIntensity
        sr.Spread = graf.SunRaysSpread
        sr.Parent = Lighting
        srNuevo = sr
        if srOriginal then srOriginal.Parent = nil end
    end
end

local function aplicarClouds(graf)
    if cloudsNuevo then cloudsNuevo:Destroy(); cloudsNuevo = nil end
    if graf.esDefault then
        if cloudsOriginal then cloudsOriginal.Parent = Workspace end
        return
    end
    if graf.CloudsCover then
        local clouds = Instance.new("Clouds")
        clouds.Cover = graf.CloudsCover
        clouds.Density = graf.CloudsDensity
        clouds.Color = graf.CloudsColor
        clouds.Parent = Workspace
        cloudsNuevo = clouds
        if cloudsOriginal then cloudsOriginal.Parent = nil end
    end
end

local function aplicarGrafico(numeroGrafico)
    local graf = GRAFICOS[numeroGrafico]
    if not graf then return end
    
    if graf.esDefault then
        restaurarGraficoOriginal()
        return
    end
    
    pcall(function()
        Lighting.Ambient = graf.Ambient
        Lighting.Brightness = graf.Brightness
        Lighting.OutdoorAmbient = graf.OutdoorAmbient
        Lighting.ClockTime = graf.ClockTime
        Lighting.FogColor = graf.FogColor
        Lighting.FogEnd = graf.FogEnd
        Lighting.FogStart = graf.FogStart
        Lighting.ColorShift_Top = graf.ColorShift_Top
        Lighting.ColorShift_Bottom = graf.ColorShift_Bottom
        Lighting.EnvironmentDiffuseScale = graf.EnvironmentDiffuseScale
        Lighting.EnvironmentSpecularScale = graf.EnvironmentSpecularScale
        Lighting.GlobalShadows = graf.GlobalShadows
    end)
    
    pcall(function() aplicarSkybox(graf) end)
    pcall(function() aplicarAtmosphere(graf) end)
    pcall(function() aplicarBloom(graf) end)
    pcall(function() aplicarColorCorrection(graf) end)
    pcall(function() aplicarSunRays(graf) end)
    pcall(function() aplicarClouds(graf) end)
end

function restaurarGraficoOriginal()
    pcall(function()
        Lighting.Ambient = luzOriginal.Ambient
        Lighting.Brightness = luzOriginal.Brightness
        Lighting.OutdoorAmbient = luzOriginal.OutdoorAmbient
        Lighting.ClockTime = luzOriginal.ClockTime
        Lighting.FogColor = luzOriginal.FogColor
        Lighting.FogEnd = luzOriginal.FogEnd
        Lighting.FogStart = luzOriginal.FogStart
        Lighting.ColorShift_Top = luzOriginal.ColorShift_Top
        Lighting.ColorShift_Bottom = luzOriginal.ColorShift_Bottom
        Lighting.EnvironmentDiffuseScale = luzOriginal.EnvironmentDiffuseScale
        Lighting.EnvironmentSpecularScale = luzOriginal.EnvironmentSpecularScale
        Lighting.GlobalShadows = luzOriginal.GlobalShadows
    end)
    
    pcall(function()
        if skyNuevo then skyNuevo:Destroy(); skyNuevo = nil end
        if skyOriginal and not skyOriginal.Parent then skyOriginal.Parent = Lighting end
        if atmosNuevo then atmosNuevo:Destroy(); atmosNuevo = nil end
        if atmosOriginal and not atmosOriginal.Parent then atmosOriginal.Parent = Lighting end
        if bloomNuevo then bloomNuevo:Destroy(); bloomNuevo = nil end
        if bloomOriginal and not bloomOriginal.Parent then bloomOriginal.Parent = Lighting end
        if ccNuevo then ccNuevo:Destroy(); ccNuevo = nil end
        if ccOriginal and not ccOriginal.Parent then ccOriginal.Parent = Lighting end
        if srNuevo then srNuevo:Destroy(); srNuevo = nil end
        if srOriginal and not srOriginal.Parent then srOriginal.Parent = Lighting end
        if cloudsNuevo then cloudsNuevo:Destroy(); cloudsNuevo = nil end
        if cloudsOriginal and not cloudsOriginal.Parent then cloudsOriginal.Parent = Workspace end
    end)
end

-- ============ CÁMARA CINEMÁTICA CON VELOCIDAD AJUSTABLE ============
local function detenerCine()
    cineActivo = false
    cineTomaActual = 0
    cineAngulo = 0
    cineSuavizado = nil
    if cineConexion then
        cineConexion:Disconnect()
        cineConexion = nil
    end
    btnCine.BackgroundColor3 = Color3.fromRGB(150, 50, 200)
    btnCine.Text = "🎬 Cine"
    camera.FieldOfView = fovOriginal
end

local function iniciarToma(numeroToma)
    local toma = TOMAS[numeroToma]
    if not toma then return end
    cineTomaActual = numeroToma
    cineActivo = true
    cineAngulo = 0
    cineSuavizado = nil
    btnCine.BackgroundColor3 = Color3.fromRGB(255, 180, 0)
    btnCine.Text = "🎬 " .. numeroToma .. "/" .. #TOMAS
    local char = player.Character
    if not char then return end
    cinePersonaje = char:FindFirstChild("HumanoidRootPart")
    if not cinePersonaje then return end
    if cineConexion then cineConexion:Disconnect() end
    
    local radioActual = toma.radio
    local alturaActual = toma.altura
    
    cineConexion = RunService.RenderStepped:Connect(function(dt)
        if not cineActivo then return end
        if not cinePersonaje or not cinePersonaje.Parent then return end
        if cineTomaActual ~= numeroToma then return end
        
        -- ✅ LA VELOCIDAD AHORA DEPENDE DE LA BARRITA
        -- velocidad va de 10 a 300, la normalizamos a un multiplicador
        -- 60 = velocidad normal (1.0x), 10 = lento (0.2x), 300 = rápido (3.0x)
        local multiplicadorVelocidad = velocidad / 60
        
        cineAngulo = cineAngulo + toma.velocidadGiro * multiplicadorVelocidad * dt
        
        -- Espiral
        if toma.espiral then
            radioActual = radioActual + toma.espiral * multiplicadorVelocidad * dt
            alturaActual = alturaActual + math.abs(toma.espiral) * 0.3 * multiplicadorVelocidad * dt
        end
        
        -- Acercarse
        if toma.acercarse then
            radioActual = math.max(8, radioActual - 5 * multiplicadorVelocidad * dt)
        end
        
        camera.FieldOfView = toma.fov
        
        local offsetX = math.cos(cineAngulo) * radioActual
        local offsetZ = math.sin(cineAngulo) * radioActual
        
        local posObjetivo = cinePersonaje.Position + Vector3.new(offsetX, alturaActual, offsetZ)
        local lookAt = cinePersonaje.Position + Vector3.new(0, 1.5, 0)
        
        local camObjetivo = CFrame.new(posObjetivo, lookAt) * CFrame.Angles(toma.inclinacion, 0, 0)
        
        if not cineSuavizado then cineSuavizado = camObjetivo end
        cineSuavizado = cineSuavizado:Lerp(camObjetivo, 0.15)
        camera.CFrame = cineSuavizado
    end)
end

local function siguienteToma()
    if not cineActivo then
        iniciarToma(1)
        return
    end
    local siguiente = cineTomaActual + 1
    if siguiente > #TOMAS then
        detenerCine()
    else
        iniciarToma(siguiente)
    end
end

-- ============ ACTIVAR / DESACTIVAR ============
local function activar()
    activo = true
    camaraOriginal = camera.CameraType
    sujetoOriginal = camera.CameraSubject
    cframeOriginal = camera.CFrame
    fovOriginal = camera.FieldOfView
    local look = camera.CFrame.LookVector
    yaw = math.atan2(-look.X, -look.Z)
    pitch = math.asin(look.Y)
    posicionCamara = camera.CFrame.Position
    camera.CameraType = Enum.CameraType.Scriptable
    camera.CameraSubject = nil
    controles.Visible = true
    btnActivar.Visible = false
    congelarPersonaje()
end

local function desactivar()
    activo = false
    detenerCine()
    restaurarGraficoOriginal()
    graficoActual = 0
    btnGraficos.Text = "🎨 Gráficos"
    btnGraficos.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
    camera.CameraType = camaraOriginal
    camera.CameraSubject = sujetoOriginal
    camera.CFrame = cframeOriginal
    camera.FieldOfView = fovOriginal
    controles.Visible = false
    btnActivar.Visible = true
    btnX.Visible = false
    if modoLimpioActivo then desactivarModoLimpio() end
    if personajeOculto then mostrarPersonaje(); personajeOculto = false; btnOcultar.Text = "Ocultarme" end
    descongelarPersonaje()
end

-- ============ BOTONES ============
btnActivar.MouseButton1Click:Connect(activar)
btnCerrar.MouseButton1Click:Connect(desactivar)

btnLimpio.MouseButton1Click:Connect(function()
    if modoLimpioActivo then desactivarModoLimpio() else activarModoLimpio() end
end)

btnOcultar.MouseButton1Click:Connect(function()
    if personajeOculto then
        mostrarPersonaje()
        personajeOculto = false
        btnOcultar.Text = "Ocultarme"
    else
        ocultarPersonaje()
        personajeOculto = true
        btnOcultar.Text = "Mostrarme"
    end
end)

btnGraficos.MouseButton1Click:Connect(function()
    graficoActual = graficoActual + 1
    if graficoActual > #GRAFICOS then
        graficoActual = 0
        restaurarGraficoOriginal()
        btnGraficos.Text = "🎨 Gráficos"
        btnGraficos.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
    else
        aplicarGrafico(graficoActual)
        btnGraficos.Text = "🎨 " .. GRAFICOS[graficoActual].nombre
        btnGraficos.BackgroundColor3 = Color3.fromRGB(255, 140, 50)
    end
end)

btnCine.MouseButton1Click:Connect(siguienteToma)

btnX.MouseButton1Click:Connect(function()
    desactivarModoLimpio()
end)

-- ============ SLIDER VELOCIDAD ============
local arrastrandoS = false

sliderFondo.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        arrastrandoS = true
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if not arrastrandoS then return end
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement then
        local posX = input.Position.X
        local inicioX = sliderFondo.AbsolutePosition.X
        local ancho = sliderFondo.AbsoluteSize.X
        local pct = math.clamp((posX - inicioX) / ancho, 0, 1)
        sliderRelleno.Size = UDim2.new(pct, 0, 1, 0)
        velocidad = 10 + (pct * 290)
        labelVel.Text = "Vel " .. math.floor(velocidad)
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        arrastrandoS = false
    end
end)

-- ============ JOYSTICK ============
local joyTouchId = nil
local joyCentro = nil
local direccionJoystick = Vector3.zero

joyFondo.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch then
        if joyTouchId == nil then
            joyTouchId = input
            joyCentro = Vector2.new(joyFondo.AbsolutePosition.X + 50, joyFondo.AbsolutePosition.Y + 50)
        end
    elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
        joyTouchId = "mouse"
        joyCentro = Vector2.new(joyFondo.AbsolutePosition.X + 50, joyFondo.AbsolutePosition.Y + 50)
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if joyTouchId == nil then return end
    if input ~= joyTouchId and input.UserInputType == Enum.UserInputType.Touch then return end
    if input.UserInputType == Enum.UserInputType.MouseMovement and joyTouchId ~= "mouse" then return end
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement then
        local pos = Vector2.new(input.Position.X, input.Position.Y)
        local delta = pos - joyCentro
        local maxD = 40
        if delta.Magnitude > maxD then delta = delta.Unit * maxD end
        joyBola.Position = UDim2.new(0.5, delta.X - 21, 0.5, delta.Y - 21)
        direccionJoystick = Vector3.new(delta.X / maxD, 0, delta.Y / maxD)
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input == joyTouchId then
        joyTouchId = nil
        joyBola.Position = UDim2.new(0.5, -21, 0.5, -21)
        direccionJoystick = Vector3.zero
    end
    if input.UserInputType == Enum.UserInputType.MouseButton1 and joyTouchId == "mouse" then
        joyTouchId = nil
        joyBola.Position = UDim2.new(0.5, -21, 0.5, -21)
        direccionJoystick = Vector3.zero
    end
    if input.UserInputType == Enum.UserInputType.Touch then
        subiendo = false
        bajando = false
    end
end)

-- ============ BOTONES ▲▼ ============
btnSubir.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then subiendo = true end
end)
btnBajar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then bajando = true end
end)
btnSubir.InputEnded:Connect(function() subiendo = false end)
btnBajar.InputEnded:Connect(function() bajando = false end)

-- ============ ROTACIÓN LIBRE ============
local toquesRotar = {}

UserInputService.TouchStarted:Connect(function(input, gp)
    if not activo then return end
    if cineActivo then return end
    if gp then return end
    if input.UserInputType ~= Enum.UserInputType.Touch then return end
    if input == joyTouchId then return end
    toquesRotar[input] = input.Position
end)

UserInputService.TouchMoved:Connect(function(input, gp)
    if not activo then return end
    if cineActivo then return end
    if input.UserInputType ~= Enum.UserInputType.Touch then return end
    if input == joyTouchId then return end
    if toquesRotar[input] then
        local anterior = toquesRotar[input]
        local delta = input.Position - anterior
        yaw = yaw - math.rad(delta.X * sensibilidad)
        pitch = pitch - math.rad(delta.Y * sensibilidad)
        pitch = math.clamp(pitch, -limitePitch, limitePitch)
        toquesRotar[input] = input.Position
    end
end)

UserInputService.TouchEnded:Connect(function(input)
    if toquesRotar[input] then toquesRotar[input] = nil end
end)

local mouseDown = false
UserInputService.InputBegan:Connect(function(input, gp)
    if gp or not activo or cineActivo then return end
    if input.UserInputType == Enum.UserInputType.MouseButton2 then mouseDown = true end
end)

UserInputService.InputChanged:Connect(function(input)
    if mouseDown and activo and not cineActivo and input.UserInputType == Enum.UserInputType.MouseMovement then
        yaw = yaw - math.rad(input.Delta.X * sensibilidad)
        pitch = pitch - math.rad(input.Delta.Y * sensibilidad)
        pitch = math.clamp(pitch, -limitePitch, limitePitch)
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then mouseDown = false end
end)

-- ============ LOOP PRINCIPAL ============
RunService.RenderStepped:Connect(function(dt)
    if not activo then return end
    if cineActivo then return end
    
    if direccionJoystick.Magnitude > 0.05 then
        local yawCF = CFrame.Angles(0, yaw, 0)
        local adelante = yawCF.LookVector
        local derecha = yawCF.RightVector
        local dir = (adelante * -direccionJoystick.Z) + (derecha * direccionJoystick.X)
        if dir.Magnitude > 0 then dir = dir.Unit end
        posicionCamara = posicionCamara + dir * (velocidad / 60) * dt * 60
    end
    if subiendo then posicionCamara = posicionCamara + Vector3.new(0, (velocidad / 60) * dt * 60, 0) end
    if bajando then posicionCamara = posicionCamara - Vector3.new(0, (velocidad / 60) * dt * 60, 0) end
    camera.CFrame = CFrame.new(posicionCamara) * CFrame.Angles(0, yaw, 0) * CFrame.Angles(pitch, 0, 0)
end)

-- ============================================
-- 📸📹 SISTEMA DE CAPTURA
-- ============================================

local capturaActiva = false
local guisOcultosParaCaptura = {}
local esVideo = false

local function ocultarTodoParaCaptura()
    if capturaActiva then return end
    capturaActiva = true
    guisOcultosParaCaptura = {}
    esVideo = false
    
    for _, obj in pairs(gui:GetDescendants()) do
        if obj:IsA("GuiObject") then
            if obj.Visible then
                guisOcultosParaCaptura[obj] = true
                obj.Visible = false
            end
        end
    end
    if btnActivar.Visible then
        guisOcultosParaCaptura[btnActivar] = true
        btnActivar.Visible = false
    end
    
    task.spawn(function()
        task.wait(0.8)
        if capturaActiva then
            esVideo = true
            for obj, _ in pairs(guisOcultosParaCaptura) do
                if obj and obj.Parent then obj.Visible = true end
            end
            guisOcultosParaCaptura = {}
            capturaActiva = false
        end
    end)
end

local function restaurarDespuesCaptura()
    if not capturaActiva then return end
    capturaActiva = false
    
    if not esVideo then
        for obj, _ in pairs(guisOcultosParaCaptura) do
            if obj and obj.Parent then obj.Visible = true end
        end
    end
    guisOcultosParaCaptura = {}
    esVideo = false
    
    if not activo then btnActivar.Visible = true end
end

pcall(function()
    CaptureService.CaptureBegan:Connect(function() ocultarTodoParaCaptura() end)
    CaptureService.CaptureEnded:Connect(function()
        task.wait(0.15)
        restaurarDespuesCaptura()
    end)
end)

UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.F12 or input.KeyCode == Enum.KeyCode.Print then
        ocultarTodoParaCaptura()
    end
    if input.KeyCode == Enum.KeyCode.ButtonR1 or input.KeyCode == Enum.KeyCode.ButtonL1 then
        ocultarTodoParaCaptura()
    end
end)

pcall(function()
    local GuiService = game:GetService("GuiService")
    GuiService.MenuOpened:Connect(function() ocultarTodoParaCaptura() end)
    GuiService.MenuClosed:Connect(function()
        task.wait(0.15)
        restaurarDespuesCaptura()
    end)
end)

print("✅ Freecam v36 - COMPLETO")
print("🎬 16 cinemáticas CON VELOCIDAD AJUSTABLE")
print("🎨 12 gráficos con cielo y efectos")
print("📸📹 Fotos ocultas | Videos con botones")
print("🎚️ La barrita de velocidad controla las tomas también")