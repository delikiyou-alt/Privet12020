-- ======================= FEMBIIX · ADMIN WHITE EDITION v5 =======================
-- Устройства: ПК, планшет, телефон — интерфейс сам подбирает размер и показывает экранные кнопки на сенсоре.
-- ПК:  RightShift — скрыть/показать окно · F — действие (залп / сесть / Бобик / бросить коробку) · G — ехать к прицелу · X — отмена Бобика
-- Сенсор: тыква 🎃 — открыть окно · кнопки 🚀/🏄/🐶/💥 справа · ⬆⬇🎯🛑 слева при катании
-- Что нового:
--  • Куб теперь настоящий каркас: 12 светящихся рёбер с искрами + бегущие огоньки
--  • Новая вкладка «Толпа»: спавн кучи ракет, залп на прицел «с разных сторон»
--  • Кинематографичное интро (можно пропустить кликом / Space)
--  • Бенгальские огни: плавные переходы, шлейфы, радуга, яркость от скорости, вспышка при захвате
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SHOW_INTRO = true -- поставь false, если интро не нужно

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local TAU = math.pi * 2

-- убираем старую копию
pcall(function() RunService:UnbindFromRenderStep("FembiixMain") end)
pcall(function() RunService:UnbindFromRenderStep("FembiixRocket") end)
for _, parent in ipairs({CoreGui, player:FindFirstChild("PlayerGui")}) do
	pcall(function()
		for _, n in ipairs({"FembiixGui", "FembiixBox"}) do
			local o = parent:FindFirstChild(n)
			if o then o:Destroy() end
		end
	end)
end
pcall(function()
	for _, o in ipairs(camera:GetChildren()) do
		if o.Name:sub(1, 7) == "Fembiix" then o:Destroy() end
	end
	local o = workspace:FindFirstChild("FembiixBoxPart")
	if o then o:Destroy() end
end)

-- ============================ ХЕЛПЕРЫ ============================
local C = {
	bg = Color3.fromRGB(244, 246, 252), panel = Color3.fromRGB(255, 255, 255),
	el = Color3.fromRGB(238, 241, 249), el2 = Color3.fromRGB(224, 229, 242),
	accent = Color3.fromRGB(88, 101, 242), accentDark = Color3.fromRGB(62, 78, 226),
	green = Color3.fromRGB(32, 168, 108), danger = Color3.fromRGB(226, 66, 82),
	text = Color3.fromRGB(26, 30, 48), dim = Color3.fromRGB(112, 120, 142),
	off = Color3.fromRGB(206, 211, 226), gold = Color3.fromRGB(255, 176, 32),
}
local SPARK_C1, SPARK_C2 = Color3.fromRGB(255, 205, 80), Color3.fromRGB(255, 70, 0)

local function make(class, props, parent)
	local o = Instance.new(class)
	for k, v in pairs(props or {}) do o[k] = v end
	if parent then o.Parent = parent end
	return o
end
local function round(o, r) return make("UICorner", {CornerRadius = UDim.new(0, r)}, o) end
local function stroke(o, color, th, tr)
	return make("UIStroke", {Color = color, Thickness = th or 1, Transparency = tr or 0, ApplyStrokeMode = Enum.ApplyStrokeMode.Border}, o)
end
local function tween(o, props, t, style, dir, rep, rev)
	local tw = TweenService:Create(o, TweenInfo.new(t or 0.15, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out, rep or 0, rev or false), props)
	tw:Play()
	return tw
end
local UIK = {W = 780, H = 520}
function UIK.lum(c) return 0.299 * c.R + 0.587 * c.G + 0.114 * c.B end
function UIK.txt(bg) return (UIK.lum(bg) > 0.62) and C.text or Color3.new(1, 1, 1) end
local function setBase(b, color)
	b:SetAttribute("Base", color)
	tween(b, {BackgroundColor3 = color, TextColor3 = UIK.txt(color)}, 0.15)
end
local function attachHover(b)
	b.MouseEnter:Connect(function()
		local base = b:GetAttribute("Base")
		if base then tween(b, {BackgroundColor3 = base:Lerp((UIK.lum(base) > 0.5) and Color3.new(0, 0, 0) or Color3.new(1, 1, 1), 0.08)}, 0.1) end
	end)
	b.MouseLeave:Connect(function()
		local base = b:GetAttribute("Base")
		if base then tween(b, {BackgroundColor3 = base}, 0.1) end
	end)
end
local function button(parent, text, color, order, height)
	local b = make("TextButton", {
		Size = UDim2.new(1, 0, 0, (height or 36) + UIK.thv), BackgroundColor3 = color, AutoButtonColor = false,
		Text = text, TextColor3 = UIK.txt(color), Font = Enum.Font.GothamBold, TextSize = 13,
		LayoutOrder = order or 0, BorderSizePixel = 0,
	}, parent)
	round(b, 10)
	stroke(b, Color3.new(0, 0, 0), 1, 0.92)
	b:SetAttribute("Base", color)
	attachHover(b)
	local press = make("UIScale", {Scale = 1}, b)
	b.MouseButton1Down:Connect(function() tween(press, {Scale = 0.96}, 0.08) end)
	b.MouseButton1Up:Connect(function() tween(press, {Scale = 1}, 0.15, Enum.EasingStyle.Back) end)
	b.MouseLeave:Connect(function() tween(press, {Scale = 1}, 0.1) end)
	return b
end

local function ulower(s) -- нижний регистр с кириллицей
	local out = {}
	for _, c in utf8.codes(s) do
		if c >= 0x410 and c <= 0x42F then c += 32 elseif c == 0x401 then c = 0x451 end
		out[#out + 1] = utf8.char(c)
	end
	return table.concat(out):lower()
end

local conns = {}
local function connect(sig, fn)
	local c = sig:Connect(fn)
	conns[#conns + 1] = c
	return c
end

local function flatten(v)
	local f = Vector3.new(v.X, 0, v.Z)
	if f.Magnitude < 0.001 then return Vector3.new(0, 0, -1) end
	return f.Unit
end
local function safeUnit(v, fallback)
	if v.Magnitude < 1e-5 then return fallback end
	return v.Unit
end
local function easeOutCubic(x)
	x = math.clamp(x, 0, 1)
	return 1 - (1 - x) ^ 3
end
local function resolvePart(obj)
	if obj:IsA("BasePart") then return obj end
	return obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart", true)
end
local function getHRP()
	local c = player.Character
	return c and c:FindFirstChild("HumanoidRootPart")
end
local function getFolder()
	return workspace:FindFirstChild(player.Name .. "SpawnedInToys")
end
local function randomDir()
	local u, v = math.random() * 2 - 1, math.random() * TAU
	local s = math.sqrt(1 - u * u)
	return Vector3.new(s * math.cos(v), u, s * math.sin(v))
end
local function moveObj(obj, part, cf)
	if obj:IsA("Model") then obj:PivotTo(cf) else part.CFrame = cf end
end

local notify = function() end -- подменяется после создания интерфейса

-- ============================ ДАННЫЕ РЕЖИМОВ ============================
local ROCKET_MODES = {
	{key = "MANUAL", label = "🕹 Ручной", param = "Доп. параметр", desc = "Рулишь сам: ракета летит туда, куда смотрит камера. Крути камеру ЛКМ/ПКМ или пальцем."},
	{key = "ORBIT", label = "🌀 Орбита", param = "Доп. параметр", desc = "Круг вокруг точки старта. Радиус и скорость задаются ползунками."},
	{key = "SPIRAL_UP", label = "⤴ Спираль вверх", param = "Подъём/сек", desc = "Закручивается вверх по спирали."},
	{key = "SPIRAL_DOWN", label = "⤵ Спираль вниз", param = "Спуск/сек", desc = "Закручивается вниз по спирали."},
	{key = "PATROL", label = "📍 Патруль", param = "Доп. параметр", desc = "Летает по точкам, которые ты ставишь кнопкой «Точка» прямо в полёте."},
	{key = "HOVER_SPIN", label = "🎯 Зависание", param = "Скорость вращения", desc = "Висит на месте и медленно крутится."},
	{key = "WAVE", label = "🌊 Волна", param = "Амплитуда волны", desc = "Летит вперёд змейкой вверх-вниз."},
	{key = "PENDULUM", label = "⏱ Маятник", param = "Угол маятника", desc = "Раскачивается как маятник."},
	{key = "FIGURE8", label = "♾ Восьмёрка", param = "Доп. параметр", desc = "Рисует знак бесконечности."},
	{key = "WANDER", label = "🎲 Блуждание", param = "Доп. параметр", desc = "Случайно гуляет в пределах радиуса."},
	{key = "CINEMATIC", label = "🎬 Кино-показ", param = "Высота покачивания", desc = "Медленный облёт с вращающейся камерой для красивых кадров."},
	{key = "ZIGZAG", label = "↯ Зигзаг", param = "Длина зигзага", desc = "Летит вперёд под 45°, меняя сторону."},
	{key = "LOOP", label = "🔁 Мёртвая петля", param = "Смещение вперёд", desc = "Вертикальные петли в полёте."},
	{key = "SQUARE", label = "⬛ Квадрат", param = "Доп. параметр", desc = "Облёт квадрата со стороной 2×Радиус."},
	{key = "CORKSCREW", label = "🔩 Штопор", param = "Обороты штопора", desc = "Летит вперёд, вращаясь вокруг оси полёта."},
	{key = "HEART", label = "💜 Сердце", param = "Доп. параметр", desc = "Рисует сердце в вертикальной плоскости."},
	{key = "TORNADO", label = "🌪 Торнадо", param = "Подъём/сек", desc = "Воронка: спираль расширяется, пока поднимается."},
	{key = "PENTAGRAM", label = "⭐ Пентаграмма", param = "Доп. параметр", desc = "Рисует пентаграмму в воздухе перед тобой."},
	{key = "TREFOIL", label = "☘ Трилистник", param = "Доп. параметр", desc = "Узел-трилистник в 3D."},
	{key = "LISSAJOUS", label = "〰 Лиссажу", param = "Частота", desc = "Кривая Лиссажу. Ползунок меняет частоту, получаются разные узоры."},
	{key = "ROSE", label = "🌹 Роза", param = "Лепестки", desc = "Роза-кривая в вертикальной плоскости. Ползунок меняет число лепестков."},
	{key = "TRIANGLE", label = "🔺 Треугольник", param = "Доп. параметр", desc = "Облёт треугольника по вершинам."},
	{key = "HEXAGON", label = "⬡ Шестиугольник", param = "Доп. параметр", desc = "Облёт шестиугольника в горизонтали."},
	{key = "BOUNCE", label = "🏀 Прыжки", param = "Высота прыжка", desc = "Прыгает дугами, как мячик."},
	{key = "DASH", label = "💨 Рывки", param = "Разброс угла", desc = "Короткие рывки с остановками и случайным курсом."},
	{key = "DIVE", label = "🦅 Пике", param = "Крутизна", desc = "Набирает высоту, затем пикирует. Повторяется."},
	{key = "CHAOS", label = "🌌 Хаос", param = "Нервозность", desc = "Плавный случайный полёт в 3D (шум Перлина)."},
	{key = "SPIDER", label = "🕷 Паук", param = "Доп. параметр", desc = "Выстреливает по «лапам» и возвращается в центр."},
	{key = "BAT", label = "🦇 Летучая мышь", param = "Частота взмахов", desc = "Рваный полёт с резкими взмахами вверх-вниз и в стороны."},
	{key = "GHOST", label = "👻 Призрак", param = "Доп. параметр", desc = "Медленно дрейфует, как привидение (скорость ограничена)."},
	{key = "TORUS", label = "🍩 Тор-узел", param = "Оборотов узла", desc = "Летит по узлу на поверхности бублика (торус-узел). Ползунок меняет число оборотов."},
	{key = "SPIROGRAPH", label = "🌸 Спирограф", param = "Форма узора", desc = "Рисует узор спирографа в вертикальной плоскости."},
	{key = "BUTTERFLY", label = "🦋 Бабочка", param = "Доп. параметр", desc = "Летит по кривой-бабочке в вертикальной плоскости."},
	{key = "LAWN", label = "🌾 Газонокосилка", param = "Пауза на смене ряда", desc = "Прочёсывает область рядами туда-обратно, каждый раз сдвигаясь вбок."},
	{key = "PULSAR", label = "💥 Пульсар", param = "Доп. параметр", desc = "Стреляет лучом в новую сторону на длину Радиуса и возвращается назад — звёздный взрыв."},
	{key = "LIGHTNING", label = "⚡ Молния", param = "Частота разрядов", desc = "Резкие ломаные повороты вперёд, как разряд молнии."},
}

local SWARM_MODES = {
	{key = "DRAGON", kind = "dragon", label = "🐉 Дракон: охота", desc = "Твои ракеты строятся в ДРАКОНА: голова гонится за точкой прицела и кружит над ней, тело змеится следом. F — огненное дыхание с тряской камеры. Спаркерам включи «Дракон-огонь» — это глаза и языки пламени. Чем больше ракет, тем длиннее дракон: поставь 12–30. Включи «Кино-камеру дракона» в списке настроек."},
	{key = "DRAGON_ORBIT", kind = "dragon", label = "🐉 Дракон: круги", desc = "Дракон огромными дугами кружит высоко над тобой. F — огненное дыхание. Идеально с кино-камерой."},
	{key = "FOLLOW", kind = "pet", label = "🐕 Ходит за мной", desc = "Твоя ракета ходит за тобой, как питомец: парит у земли, покачивается и наклоняется на бегу. Несколько ракет идут клином."},
	{key = "HEAD", kind = "pet", label = "🎩 Сидит на голове", desc = "Ракета сидит у тебя на голове. Несколько ракет складываются башней."},
	{key = "ECHO", kind = "pet", label = "🔁 Эхо-хвост", desc = "РЕДКОЕ: каждая ракета повторяет ТОЧНЫЙ путь, который ты прошёл несколько секунд назад. Бежишь зигзагом — хвост рисует тот же зигзаг."},
	{key = "SATELLITES", kind = "bobik", label = "🛰 Спутники", desc = "РЕДКОЕ: F — выбрать игрока (наведи кружок), F ещё раз — ракеты выходят на орбиту вокруг него в два кольца и летят за ним. Без атаки и без лая. F — отозвать."},
	{key = "SENTRY", kind = "pet", label = "🛡 Страж", desc = "РЕДКОЕ: ракеты висят над тобой постом, нос следит за ближайшим игроком, красные лазеры показывают прицел, предупреждают, когда кто-то подошёл ближе 40 студов."},
	{key = "AUTOSHOW", kind = "pet", label = "🎬 Авто-шоу", desc = "РЕДКОЕ: формации сами меняются каждые 7 секунд — карусель, щит, нимб, спираль, крылья, стена, эскорт, конга, восьмёрка, дискотека."},
	{key = "DISCO", kind = "pet", label = "🪩 Дискотека", desc = "Ракеты кружат в такт 120 BPM: радиус и высота пульсируют, ракеты быстро вращаются."},
	{key = "HALO", kind = "pet", label = "😇 Нимб", desc = "Ракеты лежат кольцом над твоей головой и вращаются, как нимб."},
	{key = "HELIX", kind = "pet", label = "🧬 Спираль-башня", desc = "Ракеты вьются спиралью вокруг тебя снизу вверх."},
	{key = "WINGSBACK", kind = "pet", label = "🪽 Крылья", desc = "Две дуги ракет за спиной машут, как крылья."},
	{key = "GRID", kind = "pet", label = "🧱 Стена", desc = "Ракеты стоят сеткой перед тобой и покачиваются волной, как экран."},
	{key = "EIGHT", kind = "pet", label = "♾ Восьмёрка", desc = "Ракеты летят по восьмёрке вокруг тебя."},
	{key = "CAROUSEL", kind = "pet", label = "🎠 Карусель", desc = "Ракеты кружатся вокруг тебя, как на карусели, покачиваясь вверх-вниз."},
	{key = "CONGA", kind = "pet", label = "🐍 Конга", desc = "Ракеты бегут змейкой друг за другом и виляют из стороны в сторону."},
	{key = "PUPPY", kind = "pet", label = "🐶 Щенячья радость", desc = "Ракеты прыгают, виляют хвостом и делают сальто."},
	{key = "SHIELD", kind = "pet", label = "🛡 Щит", desc = "Ракеты быстро вращаются вокруг тела наклонным кольцом, как защитный щит."},
	{key = "ESCORT", kind = "pet", label = "🦅 Эскорт", desc = "Ракеты летят по бокам и чуть сзади клином, как эскадрилья, и машут «крыльями»."},
	{key = "RIDE", kind = "ride", label = "🏄 Катаюсь на ней", desc = "F — ракета встаёт под тебя, и ты едешь на ней. WASD — ехать (куда смотрит камера), Пробел — вверх, Ctrl — вниз. G, ЛКМ по земле или кнопка 🎯 — автопоездка к точке прицела. F — слезть."},
	{key = "BOBIK", kind = "bobik", label = "🐶 Бобик, фас!", desc = "F — выбрать цель: наведи кружок на игрока (он подсветится), F ещё раз — «Бобик, фас!». Ракета с лаем (слышишь только ты) летит в игрока на полной скорости. X — отмена."},
	{key = "CROWD", kind = "volley", label = "💥 Толпа за прицелом", desc = "Нажимаешь «Запустить»: все ракеты налетают на точку прицела с разных сторон, проносятся сквозь неё и возвращаются. Следят за прицелом в реальном времени."},
	{key = "SINGLE", kind = "volley", label = "💥 1 ракета за прицелом", desc = "Одна ракета висит на точке прицела и следует за ним. Остальные гуляют за тобой."},
	{key = "RING", kind = "volley", label = "💥 Кольцо вокруг цели", desc = "Ракеты вращаются кольцом вокруг точки прицела."},
	{key = "SPHERE", kind = "volley", label = "💥 Сфера вокруг цели", desc = "Ракеты образуют вращающуюся сферу вокруг точки прицела."},
	{key = "VORTEX", kind = "volley", label = "💥 Вихрь вокруг цели", desc = "Ракеты закручиваются вихрем вокруг точки прицела, поднимаясь и опускаясь."},
	{key = "RAIN", kind = "volley", label = "💥 Ракетный дождь", desc = "Ракеты падают сверху на область вокруг прицела, потом взлетают и падают снова."},
}

local SPARK_MODES = {
	{key = "HEART", label = "💜 Сердце", desc = "Сердце за спиной: бьётся и плывёт по контуру."},
	{key = "CIRCLE", label = "⭕ Кольцо", desc = "Вращающееся кольцо вокруг тебя с лёгким волнением."},
	{key = "CUBE", label = "🧊 Куб", desc = "Светящийся каркас куба: 12 рёбер с искрами, огни сидят в вершинах, лишние бегут по рёбрам."},
	{key = "TORNADO", label = "🌪 Торнадо", desc = "Воронка вокруг тебя, расширяется кверху."},
	{key = "BLACKHOLE", label = "🕳 Чёрная дыра", desc = "Спаркеры затягивает в воронку перед тобой и выбрасывает обратно."},
	{key = "TAIL", label = "🐍 Хвост", desc = "Живая цепочка, которая тянется за тобой и виляет."},
	{key = "WINGS", label = "🦋 Крылья", desc = "Два крыла за спиной, которые машут."},
	{key = "DNA", label = "🧬 ДНК", desc = "Двойная спираль вокруг тела."},
	{key = "ATOM", label = "⚛ Атом", desc = "Три орбиты, пересекающиеся над тобой."},
	{key = "PENTAGRAM", label = "🔮 Пентаграмма", desc = "Горящая пентаграмма в круге у твоих ног, огни бегут по линиям."},
	{key = "SPHERE", label = "🪩 Сфера", desc = "Вращающаяся сфера из огней над головой."},
	{key = "INFINITY", label = "♾ Бесконечность", desc = "Огни рисуют восьмёрку над головой."},
	{key = "COMET", label = "☄ Комета", desc = "Яркая голова и хвост кружат вокруг тебя по наклонной орбите."},
	{key = "WAVE", label = "🌊 Волна", desc = "Линия огней перед тобой бегущей волной."},
	{key = "TREFOIL", label = "☘ Узел-трилистник", desc = "Огни бегут по 3D-узлу-трилистнику над тобой."},
	{key = "SPIROGRAPH", label = "🌸 Спирограф", desc = "Узор спирографа в воздухе перед тобой."},
	{key = "LISSAJOUS", label = "〰 Лиссажу", desc = "Огни рисуют фигуру Лиссажу над головой."},
	{key = "RIPPLE", label = "💧 Круги по воде", desc = "От тебя по земле расходятся три светящихся кольца."},
	{key = "METEORS", label = "☄ Метеорный дождь", desc = "Огни падают с неба, как метеоры, и снова взлетают."},
	{key = "STAR8", label = "✴ Звезда", desc = "Вращающаяся многоконечная звезда с каркасом перед тобой."},
	{key = "SATURN", label = "🪐 Сатурн", desc = "Огонь-планета в центре и наклонное кольцо вокруг."},
	{key = "ROSE", label = "🌹 Роза", desc = "Четырёхлепестковая роза перед тобой."},
	{key = "BUTTERFLY", label = "🦋 Бабочка", desc = "Огни вычерчивают кривую-бабочку."},
	{key = "BOUNCE", label = "🏀 Мячики", desc = "Огни прыгают по кругу, как мячи."},
	{key = "PILLAR", label = "🏛 Световой столб", desc = "Огни бегают вверх-вниз по вертикальному столбу вокруг тебя."},
	{key = "WEB", label = "🕸 Паутина", desc = "Спираль-паутина в вертикальной плоскости."},
	{key = "JELLY", label = "🪼 Медуза", desc = "Купол из огней над головой и щупальца, которые колышутся."},
	{key = "TURBINE", label = "🌀 Турбина", desc = "Лопасти из огней крутятся перед тобой, как вентилятор."},
	{key = "COASTER", label = "🎢 Горки", desc = "Огни несутся по кольцу с горками и провалами."},
	{key = "SCANNER", label = "📡 Сканер", desc = "Вертикальная линия огней сканирует пространство влево-вправо."},
	{key = "NEWTON", label = "⚖ Колыбель Ньютона", desc = "Шары на нитях: крайние качаются по очереди."},
	{key = "LIGHTHOUSE", label = "🗼 Маяк", desc = "Два луча из огней вращаются вокруг тебя."},
	{key = "FOUNTAIN", label = "⛲ Фонтан", desc = "Огни взлетают дугами и падают, как струи фонтана."},
	{key = "LIGHTNING", label = "⚡ Разряд", desc = "Зигзаг-молния из огней перед тобой, дёргается."},
	{key = "DRAGON", label = "🐉 Дракон-огонь", desc = "Работает вместе с режимом питомца «Дракон»: два огня — глаза, остальные — гребень пламени по спине, а при дыхании вылетают языками огня вперёд."},
	{key = "PYRAMID", label = "🔺 Пирамида", desc = "Светящийся каркас пирамиды над головой: огни в вершинах, лишние бегут по рёбрам."},
	{key = "GALAXY", label = "🌌 Галактика", desc = "Спиральная галактика: три рукава закручиваются над тобой."},
	{key = "FIREWORK", label = "🎇 Салют", desc = "Огни разлетаются шаром, повисают и падают, потом собираются и взрываются снова."},
	{key = "ORBITS", label = "🪐 Планеты", desc = "Каждый огонь — планета на своей наклонной орбите вокруг тебя."},
	{key = "CROWN", label = "👑 Корона", desc = "Корона над головой: зубцы из огней и светящийся контур."},
	{key = "NAME", label = "✍ Надпись", desc = "Огни — это перья: 5 штук очень быстро обводят буквы и пишут в воздухе слово (по умолчанию FEMBIIX). Текст меняется внизу списка настроек."},
}
local ROCKET_BY_KEY, SPARK_BY_KEY, SWARM_BY_KEY = {}, {}, {}
for _, m in ipairs(ROCKET_MODES) do ROCKET_BY_KEY[m.key] = m end
for _, m in ipairs(SPARK_MODES) do SPARK_BY_KEY[m.key] = m end
for _, m in ipairs(SWARM_MODES) do SWARM_BY_KEY[m.key] = m end

-- ============================ СОСТОЯНИЕ ============================
local ui = {}
local rocketModeKey, sparkModeKey, swarmModeKey = "MANUAL", "HEART", "FOLLOW"
local captureRange = 30
local autoCapture, sparkFx, sparkTrail, sparkRainbow = true, true, true, true
local showCrosshair, showBodyBox = true, true
local introActive = false

-- одиночная ракета
local isFirstPerson, isFreecam = false, false
local activeRocket, mainPart, bv, bg = nil, nil, nil, nil
local unbindCooldown = 0
local launched, armedCFrame = false, nil
local yaw, pitch, freecamYaw, freecamPitch, lockedYaw, lockedPitch = 0, 0, 0, 0, 0, 0
local center, startTime, initialForward = Vector3.zero, os.clock(), Vector3.new(0, 0, -1)
local waypoints, patrolIndex, polyIdx = {}, 1, 1
local wanderDir, wanderOffset, nextWanderChange = Vector3.new(1, 0, 0), Vector3.zero, 0
local lightningDir, lightningNext = Vector3.new(0, 0, -1), 0
local modeSwitchReset = true

-- толпа ракет
local swarmEnabled, swarmLaunched = false, false
local swarmAuto, swarmTeleport = true, false
local swarmRockets, swarmSet = {}, {}
local swarmT0, swarmCapTimer = 0, 0
local aimPoint, aimReady = Vector3.zero, false
local spawning = false
local API = {}
local DEVICE = (UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled)
	and ((camera.ViewportSize.X >= 900 and camera.ViewportSize.Y >= 600) and "ПЛАНШЕТ" or "ТЕЛЕФОН") or "ПК"
local touchUiOn = (DEVICE ~= "ПК") -- экранные кнопки (можно переключить в настройках)
UIK.thv = (DEVICE ~= "ПК") and 8 or 0 -- на сенсоре кнопки выше
API.cfg = {introMode = "full", userMul = 1, fav = {}}
pcall(function() -- настройки сохраняются в файл (если экзекутор умеет writefile)
	if isfile and readfile and isfile("Fembiix_v5.json") then
		for k, v in pairs(game:GetService("HttpService"):JSONDecode(readfile("Fembiix_v5.json"))) do API.cfg[k] = v end
	end
end)
if type(API.cfg.fav) ~= "table" then API.cfg.fav = {} end
if API.cfg.touchUi ~= nil then touchUiOn = API.cfg.touchUi end
function API.save()
	if API.saveQ then return end
	API.saveQ = true
	task.delay(1, function()
		API.saveQ = false
		pcall(function() if writefile then writefile("Fembiix_v5.json", game:GetService("HttpService"):JSONEncode(API.cfg)) end end)
	end)
end
function API.safe(tag, fn, ...) -- ошибка в одном модуле не ломает остальные
	local ok, err = pcall(fn, ...)
	if not ok then
		local t = os.clock()
		if (API.lastErr or 0) < t - 3 then
			API.lastErr = t
			warn("[Fembiix] " .. tag .. ": " .. tostring(err))
			notify("⚠ Ошибка в модуле: " .. tag, C.danger)
		end
	end
end
local TXT = {text = "FEMBIIX"}
pcall(function() local s = game:GetService("SoundService"):FindFirstChild("FembiixBark") if s then s:Destroy() end end)

-- спаркеры
local sparklers, sparklerSet = {}, {}
local tail = {}
local baseLook = Vector3.new(0, 0, -1)
local captureTimer = 0
local sparkMorph = false

local function resetModeState()
	center = mainPart and mainPart.Position or center
	startTime = os.clock()
	initialForward = flatten(camera.CFrame.LookVector)
	wanderOffset = Vector3.zero
	wanderDir = initialForward
	nextWanderChange = 0
	patrolIndex, polyIdx = 1, 1
	lightningNext = 0
	lightningDir = initialForward
end

-- ============================ ЛОГИКА ОДИНОЧНОЙ РАКЕТЫ ============================
local function setRkStatus(txt)
	if ui.rkStatus and ui.rkStatus.Text ~= txt then ui.rkStatus.Text = txt end
end

local function setFreecam(on)
	if on == isFreecam then return end
	isFreecam = on
	if on then
		freecamYaw, freecamPitch = yaw, pitch
		lockedYaw, lockedPitch = yaw, pitch
	else
		yaw, pitch = freecamYaw, freecamPitch
	end
	if ui.freecamBtn then
		ui.freecamBtn.Text = on and "👁 ОБЗОР: ВКЛ" or "👁 ОБЗОР: ВЫКЛ"
		setBase(ui.freecamBtn, on and C.green or C.el2)
	end
end

local function currentForward()
	local y = isFreecam and lockedYaw or yaw
	return flatten(CFrame.Angles(0, y, 0).LookVector)
end

local function restoreRocketVisibility()
	if activeRocket then
		for _, part in ipairs(activeRocket:GetDescendants()) do
			if part:IsA("BasePart") then part.LocalTransparencyModifier = 0 end
		end
	end
end

local mouseDragging, dragTouch = false, nil
local function stopDrag()
	mouseDragging, dragTouch = false, nil
	UserInputService.MouseBehavior = Enum.MouseBehavior.Default
	UserInputService.MouseIconEnabled = true
end

local function resetCameraToPlayer()
	restoreRocketVisibility()
	camera.CameraType = Enum.CameraType.Custom
	local char = player.Character
	if char and char:FindFirstChildOfClass("Humanoid") then
		camera.CameraSubject = char:FindFirstChildOfClass("Humanoid")
	end
	stopDrag()
	launched, armedCFrame = false, nil
	if ui.hint then ui.hint.Visible = false end
end

local function findRocketDirectly()
	if swarmEnabled then return nil end -- в режиме толпы одиночную ракету не берём
	local hrp, folder = getHRP(), getFolder()
	if not hrp or not folder then return nil end
	for _, child in ipairs(folder:GetChildren()) do
		if child.Name == "BombMissile" and not swarmSet[child] then
			local part = resolvePart(child)
			if part and (part.Position - hrp.Position).Magnitude <= captureRange then
				return child
			end
		end
	end
	return nil
end

local function launchRocket()
	if launched or not mainPart then return end
	launched = true
	resetModeState()
	initialForward = currentForward()
	wanderDir = initialForward
	modeSwitchReset = false
	if ui.hint then ui.hint.Visible = false end
end

local function cancelRocket()
	local wasLaunched = launched
	resetCameraToPlayer()
	if not wasLaunched then -- ракету не запускали: отпускаем, чтобы не висела
		if bv then pcall(function() bv:Destroy() end) end
		if bg then pcall(function() bg:Destroy() end) end
	end
	bv, bg = nil, nil
	activeRocket, mainPart = nil, nil
	setFreecam(false)
	unbindCooldown = 1.5
end

local function pointerHitsRocket(vp)
	if not activeRocket or not mainPart then return false end
	local ray = camera:ViewportPointToRay(vp.X, vp.Y)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = {activeRocket}
	if workspace:Raycast(ray.Origin, ray.Direction * 2000, params) then return true end
	local sp, onScreen = camera:WorldToViewportPoint(mainPart.Position)
	return onScreen and (Vector2.new(sp.X, sp.Y) - vp).Magnitude < 70
end

local function applyRotation(dx, dy, sens)
	if isFreecam then
		freecamYaw -= dx * sens
		freecamPitch = math.clamp(freecamPitch - dy * sens, -1.4, 1.4)
	else
		yaw -= dx * sens
		pitch = math.clamp(pitch - dy * sens, -1.4, 1.4)
	end
end

local overMain, overBubble = false, false
local function overGui() return overMain or overBubble end

connect(UserInputService.InputBegan, function(input, processed)
	if not activeRocket then return end
	local ut = input.UserInputType
	if ut == Enum.UserInputType.Touch then
		if processed then return end
		if not launched then
			local inset = GuiService:GetGuiInset()
			if pointerHitsRocket(Vector2.new(input.Position.X + inset.X, input.Position.Y + inset.Y)) then
				launchRocket()
			end
		end
		if not dragTouch then dragTouch = input end
	elseif ut == Enum.UserInputType.MouseButton1 or ut == Enum.UserInputType.MouseButton2 then
		if overGui() then return end
		if ut == Enum.UserInputType.MouseButton1 and not launched then
			if pointerHitsRocket(UserInputService:GetMouseLocation()) then launchRocket() end
		end
		mouseDragging = true
		UserInputService.MouseBehavior = Enum.MouseBehavior.LockCurrentPosition
		UserInputService.MouseIconEnabled = false
	end
end)
connect(UserInputService.InputChanged, function(input)
	if not activeRocket then return end
	local ut = input.UserInputType
	if ut == Enum.UserInputType.MouseMovement and mouseDragging then
		applyRotation(input.Delta.X, input.Delta.Y, 0.0035)
	elseif ut == Enum.UserInputType.Touch and input == dragTouch then
		applyRotation(input.Delta.X, input.Delta.Y, 0.004)
	end
end)
connect(UserInputService.InputEnded, function(input)
	local ut = input.UserInputType
	if ut == Enum.UserInputType.MouseButton1 or ut == Enum.UserInputType.MouseButton2 then
		if mouseDragging then stopDrag() end
	elseif ut == Enum.UserInputType.Touch and input == dragTouch then
		dragTouch = nil
	end
end)

-- ---------- траектории ракеты ----------
local function tangent(fn, t)
	return safeUnit(fn(t + 0.02) - fn(t), initialForward)
end

local function followVerts(verts, speed)
	if not mainPart then return initialForward end
	polyIdx = ((polyIdx - 1) % #verts) + 1
	local to = verts[polyIdx] - mainPart.Position
	if to.Magnitude < math.max(4, speed * 0.06) then
		polyIdx = (polyIdx % #verts) + 1
		to = verts[polyIdx] - mainPart.Position
	end
	return safeUnit(to, initialForward)
end

local function computeMode(dt, t)
	local speed = ui.rkSpeed.Get()
	local R = math.max(ui.rkRadius.Get(), 3)
	local P = ui.rkParam.Get()
	local mode = rocketModeKey
	local fwd = initialForward
	local up = Vector3.yAxis
	local right = fwd:Cross(up)

	if mode == "MANUAL" then
		local fy = isFreecam and lockedYaw or yaw
		local fp = isFreecam and lockedPitch or pitch
		local dir = (CFrame.Angles(0, fy, 0) * CFrame.Angles(fp, 0, 0)).LookVector
		return dir, dir

	elseif mode == "ORBIT" then
		local w = speed / R
		local dir = tangent(function(x) return Vector3.new(math.cos(x * w) * R, 0, math.sin(x * w) * R) end, t)
		return dir, dir

	elseif mode == "SPIRAL_UP" or mode == "SPIRAL_DOWN" then
		local climb = P * (mode == "SPIRAL_UP" and 1 or -1)
		local w = speed / R
		local dir = tangent(function(x) return Vector3.new(math.cos(x * w) * R, x * climb, math.sin(x * w) * R) end, t)
		return dir, dir

	elseif mode == "HOVER_SPIN" then
		return Vector3.zero, CFrame.Angles(0, t * (P * 0.1), 0).LookVector

	elseif mode == "WAVE" then
		local dir = tangent(function(x) return fwd * (x * speed) + up * (math.sin(x * 1.5) * P) end, t)
		return dir, dir

	elseif mode == "PENDULUM" then
		local maxA = math.rad(math.clamp(P, 5, 80))
		local rate = speed / R
		local dir = tangent(function(x)
			local a = math.sin(x * rate) * maxA
			return right * math.sin(a) * R + up * (R * (1 - math.cos(a)))
		end, t)
		return dir, dir

	elseif mode == "FIGURE8" then
		local w = speed / R
		local dir = tangent(function(x)
			local a = x * w
			local d = 1 + math.sin(a) ^ 2
			return Vector3.new(R * math.cos(a) / d, 0, R * math.sin(a) * math.cos(a) / d)
		end, t)
		return dir, dir

	elseif mode == "WANDER" then
		if t > nextWanderChange then
			local ang = math.atan2(wanderDir.Z, wanderDir.X) + (math.random() - 0.5) * 1.4
			wanderDir = Vector3.new(math.cos(ang), 0, math.sin(ang))
			nextWanderChange = t + math.random(1, 3)
		end
		wanderOffset += wanderDir * speed * dt
		if wanderOffset.Magnitude > R then wanderDir = (-wanderOffset).Unit end
		return wanderDir, wanderDir

	elseif mode == "PATROL" then
		if #waypoints == 0 or not mainPart then return Vector3.zero, initialForward end
		patrolIndex = ((patrolIndex - 1) % #waypoints) + 1
		local to = waypoints[patrolIndex] - mainPart.Position
		if to.Magnitude < math.max(4, speed * 0.06) then
			patrolIndex = (patrolIndex % #waypoints) + 1
			to = waypoints[patrolIndex] - mainPart.Position
		end
		local dir = safeUnit(to, initialForward)
		return dir, dir

	elseif mode == "CINEMATIC" then
		local slow = math.min(speed, 40)
		local w = slow / R
		local dir = tangent(function(x) return Vector3.new(math.cos(x * w) * R, math.sin(x * 0.5) * P, math.sin(x * w) * R) end, t)
		return dir, dir, slow

	elseif mode == "ZIGZAG" then
		local period = math.max(0.3, P * 0.1)
		local side = (math.floor(t / period) % 2 == 0) and 1 or -1
		local dir = safeUnit(fwd + right * side, fwd)
		return dir, dir

	elseif mode == "LOOP" then
		local w = speed / R
		local drift = P * 0.02
		local dir = tangent(function(x)
			local a = x * w
			return fwd * (R * math.sin(a) + drift * a * R) + up * (R * (1 - math.cos(a)))
		end, t)
		return dir, dir

	elseif mode == "SQUARE" then
		local sideTime = (2 * R) / math.max(speed, 1)
		local dirs = {fwd, right, -fwd, -right}
		local dir = dirs[(math.floor(t / sideTime) % 4) + 1]
		return dir, dir

	elseif mode == "CORKSCREW" then
		local turns, rad = P * 0.4, R * 0.5
		local dir = tangent(function(x)
			local a = x * turns
			return fwd * (x * speed) + (right * math.cos(a) + up * math.sin(a)) * rad
		end, t)
		return dir, dir

	elseif mode == "HEART" then
		local s, w = R / 16, speed * 1.1 / R
		local dir = tangent(function(x)
			local a = x * w
			local hx = 16 * math.sin(a) ^ 3
			local hy = 13 * math.cos(a) - 5 * math.cos(2 * a) - 2 * math.cos(3 * a) - math.cos(4 * a)
			return right * (hx * s) + up * (hy * s)
		end, t)
		return dir, dir

	elseif mode == "TORNADO" then
		local w = speed / R
		local dir = tangent(function(x)
			local r = R * (0.15 + 0.85 * math.min(x * 0.25, 1))
			return Vector3.new(math.cos(x * w) * r, x * P, math.sin(x * w) * r)
		end, t)
		return dir, dir

	elseif mode == "PENTAGRAM" then
		local order, verts = {0, 2, 4, 1, 3}, {}
		for i, j in ipairs(order) do
			local a = j * TAU / 5
			verts[i] = center + up * R + right * math.sin(a) * R + up * math.cos(a) * R
		end
		local dir = followVerts(verts, speed)
		return dir, dir

	elseif mode == "TRIANGLE" then
		local verts = {}
		for j = 0, 2 do
			local a = j * TAU / 3
			verts[j + 1] = center + up * (R * 0.5) + right * math.sin(a) * R + up * math.cos(a) * R
		end
		local dir = followVerts(verts, speed)
		return dir, dir

	elseif mode == "HEXAGON" then
		local verts = {}
		for j = 0, 5 do
			local a = j * TAU / 6
			verts[j + 1] = center + right * math.sin(a) * R + fwd * math.cos(a) * R
		end
		local dir = followVerts(verts, speed)
		return dir, dir

	elseif mode == "SPIDER" then
		local verts = {}
		for j = 0, 7 do
			local a = j * TAU / 8
			local lift = (j % 2 == 0) and 0.4 or -0.1
			verts[#verts + 1] = center + (right * math.sin(a) + fwd * math.cos(a)) * R + up * (R * lift)
			verts[#verts + 1] = center
		end
		local dir = followVerts(verts, speed)
		return dir, dir

	elseif mode == "TREFOIL" then
		local s, w = R / 3, speed / R * 0.6
		local dir = tangent(function(x)
			local a = x * w
			local px = math.sin(a) + 2 * math.sin(2 * a)
			local py = math.cos(a) - 2 * math.cos(2 * a)
			local pz = -math.sin(3 * a)
			return right * (px * s) + up * (py * s) + fwd * (pz * s)
		end, t)
		return dir, dir

	elseif mode == "LISSAJOUS" then
		local f = 2 + math.floor(P / 20)
		local w = speed / R * 0.7
		local dir = tangent(function(x)
			local a = x * w
			return right * (R * math.sin((f + 1) * a + math.pi / 2)) + up * (R * math.sin(f * a)) + fwd * (R * 0.6 * math.sin((f + 2) * a))
		end, t)
		return dir, dir

	elseif mode == "ROSE" then
		local k = 2 + math.floor(P / 10)
		local w = speed / R * 0.8
		local dir = tangent(function(x)
			local a = x * w
			local r = R * math.cos(k * a)
			return right * (r * math.cos(a)) + up * (r * math.sin(a))
		end, t)
		return dir, dir

	elseif mode == "BOUNCE" then
		local period = 1.3
		local tt = (t % period) / period
		local dir = safeUnit(fwd + up * ((1 - 2 * tt) * P * 0.06), fwd)
		return dir, dir

	elseif mode == "DASH" then
		local cyc = 1.2
		local n = math.floor(t / cyc)
		local ph = t - n * cyc
		local ang = math.sin(n * 12.9898) * math.rad(P * 2)
		local dir = CFrame.fromAxisAngle(up, ang):VectorToWorldSpace(fwd)
		return dir, dir, (ph < 0.4) and math.min(speed * 2, 800) or 0

	elseif mode == "DIVE" then
		local ph = t % 5
		local sign = (ph < 2.5) and 1 or -1
		local dir = safeUnit(fwd + up * (P / 15) * sign, fwd)
		return dir, dir

	elseif mode == "CHAOS" then
		local tt = t * (0.2 + P * 0.02)
		local dir = safeUnit(Vector3.new(math.noise(tt, 0.3, 0.1), math.noise(tt, 5.7, 1.3) * 0.7, math.noise(tt, 9.1, 2.4)), fwd)
		return dir, dir

	elseif mode == "BAT" then
		local fr = 0.5 + P * 0.1
		local dir = safeUnit(fwd + right * (math.sin(t * 3 * fr) * 1.1) + up * (math.sin(t * 6.5 * fr) * 0.9), fwd)
		return dir, dir

	elseif mode == "GHOST" then
		local dir = safeUnit(fwd * 0.6 + right * math.sin(t * 0.7) + up * (math.cos(t * 0.5) * 0.6), fwd)
		return dir, dir, math.min(speed, 45)

	elseif mode == "LIGHTNING" then
		if t > lightningNext then
			lightningNext = t + math.max(0.05, P * 0.01)
			lightningDir = safeUnit(fwd + right * ((math.random() * 2 - 1) * 1.6) + up * ((math.random() * 2 - 1) * 1.0), fwd)
		end
		return lightningDir, lightningDir

	elseif mode == "TORUS" then
		local w = speed / (R * 1.5)
		local q = 3 + math.floor(P / 20)
		local dir = tangent(function(x)
			local a = x * w
			local rr = R + R * 0.4 * math.cos(q * a)
			return fwd * (math.cos(a) * rr) + right * (math.sin(a) * rr) + up * (R * 0.4 * math.sin(q * a))
		end, t)
		return dir, dir

	elseif mode == "SPIROGRAPH" then
		local w = speed / R * 0.9
		local q = 0.31 + (P % 20) * 0.01
		local dir = tangent(function(x)
			local a = x * w
			local hx = (1 - q) * math.cos(a) + 0.9 * q * math.cos((1 - q) / q * a)
			local hy = (1 - q) * math.sin(a) - 0.9 * q * math.sin((1 - q) / q * a)
			return right * (hx * R) + up * (hy * R)
		end, t)
		return dir, dir

	elseif mode == "BUTTERFLY" then
		local w, s = speed / R * 0.5, R / 3
		local dir = tangent(function(x)
			local a = x * w
			local r = math.exp(math.sin(a)) - 2 * math.cos(4 * a) + math.sin((2 * a - math.pi) / 24) ^ 5
			return right * (math.sin(a) * r * s) + up * (math.cos(a) * r * s)
		end, t)
		return dir, dir

	elseif mode == "LAWN" then
		local rowTime = (2 * R) / math.max(speed, 1)
		local cyc = rowTime + math.max(0.4, P * 0.02)
		local row = math.floor(t / cyc)
		local ph = t - row * cyc
		local sgn = (row % 2 == 0) and 1 or -1
		local dir = (ph < rowTime) and (fwd * sgn) or right
		return dir, dir

	elseif mode == "PULSAR" then
		local cyc = (2 * R) / math.max(speed, 1)
		local idx = math.floor(t / cyc)
		local ph = (t - idx * cyc) / cyc
		local y = 1 - 2 * ((idx * 0.61803) % 1)
		local rr = math.sqrt(math.max(0, 1 - y * y))
		local th = idx * 2.39996
		local d = Vector3.new(math.cos(th) * rr, y, math.sin(th) * rr)
		local dir = (ph < 0.5) and d or -d
		return dir, dir
	end

	return Vector3.zero, initialForward
end

-- ============================ МОЯ ХОДЯЧАЯ РАКЕТА ============================
do
	local aimParams = RaycastParams.new()
	aimParams.FilterType = Enum.RaycastFilterType.Exclude
	local riding, rideRocket, rideTarget, rideHeading, rideUp, rideDown = false, nil, nil, Vector3.new(0, 0, -1), false, false
	local bobikState, bobikTarget, bobikRocket, bobikT0, bobikHL = "idle", nil, nil, 0, nil
	local dragonOn, dragonList, dragonFwd, dragonBreathUntil = false, {}, Vector3.new(0, 0, -1), 0
	local shakeUntil, camOwned, camPos, breathWas = 0, false, nil, false

	local function getHum()
		local c = player.Character
		return c and c:FindFirstChildOfClass("Humanoid")
	end
	local function playerHRP(p)
		local c = p and p.Character
		return c and c:FindFirstChild("HumanoidRootPart")
	end
	local function modeKind()
		local m = SWARM_BY_KEY[swarmModeKey]
		return m and m.kind or "pet"
	end
	local function mineList() -- ракеты, которые не отданы другим игрокам
		local l = {}
		for _, r in ipairs(swarmRockets) do
			if not r.owner then l[#l + 1] = r end
		end
		return l
	end

	local function computeAim()
		local origin, dir = camera.CFrame.Position, camera.CFrame.LookVector
		local filter = {}
		local char = player.Character
		if char then filter[#filter + 1] = char end
		local folder = getFolder()
		if folder then filter[#filter + 1] = folder end
		aimParams.FilterDescendantsInstances = filter
		local maxD = ui.swDist.Get()
		local hit = workspace:Raycast(origin, dir * maxD, aimParams)
		if hit then return hit.Position + hit.Normal * 2 end
		return origin + dir * maxD
	end

	local function pickTarget() -- игрок, ближе всего к центру экрана
		local vp = camera.ViewportSize / 2
		local best, bestD = nil, 170
		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= player then
				local h = playerHRP(p)
				local hum = p.Character and p.Character:FindFirstChildOfClass("Humanoid")
				if h and hum and hum.Health > 0 then
					local sp, on = camera:WorldToViewportPoint(h.Position)
					if on then
						local d = (Vector2.new(sp.X, sp.Y) - vp).Magnitude
						if d < bestD then best, bestD = p, d end
					end
				end
			end
		end
		return best
	end
	local function nearestPlayer(maxDist)
		local hrp = getHRP()
		if not hrp then return nil end
		local best, bd = nil, maxDist
		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= player then
				local h = playerHRP(p)
				if h then
					local d = (h.Position - hrp.Position).Magnitude
					if d < bd then best, bd = p, d end
				end
			end
		end
		return best
	end

	local function setAimLocked(l)
		if ui.aimStroke then ui.aimStroke.Color = l and Color3.fromRGB(90, 255, 120) or Color3.fromRGB(255, 60, 30) end
	end
	local function setTargetFx(p)
		local ch = nil
		if API.hlOn ~= false and p then ch = p.Character end
		if bobikHL and bobikHL.Adornee == ch then return end
		if bobikHL then bobikHL:Destroy(); bobikHL = nil end
		if ch then
			bobikHL = make("Highlight", {Name = "FembiixHL", Adornee = ch, FillColor = Color3.fromRGB(255, 40, 20), FillTransparency = 0.55,
				OutlineColor = Color3.fromRGB(255, 225, 90), OutlineTransparency = 0, DepthMode = Enum.HighlightDepthMode.AlwaysOnTop}, camera)
		end
	end

	-- текст/иконка главной кнопки действия (зависит от режима)
	local function actionTexts()
		local k = modeKind()
		if k == "volley" then
			return swarmLaunched and "⏹ ВЕРНУТЬ ТОЛПУ  (F)" or "🚀 ЗАПУСТИТЬ  (F)", swarmLaunched and "⏹" or "🚀", swarmLaunched
		elseif k == "ride" then
			return riding and "🛑 СЛЕЗТЬ  (F)" or "🏄 СЕСТЬ И ЕХАТЬ  (F)", riding and "🛑" or "🏄", riding
		elseif k == "bobik" then
			if bobikState == "aiming" then return "🎯 ФАС!  (F)", "🎯", true end
			if bobikState == "attack" then return "⏹ ОТЗВАТЬ БОБИКА  (F)", "⏹", true end
			return "🐶 ВЫБРАТЬ ЦЕЛЬ  (F)", "🐶", false
		end
		if k == "dragon" then
			local b = os.clock() < dragonBreathUntil
			return b and "🔥 ОГОНЬ!" or "🔥 ДЫШАТЬ ОГНЁМ  (F)", "🔥", b
		end
		return "🐕 ПРОСТО ГУЛЯЕМ", "🐕", false
	end
	local function refreshActionUi()
		local txt, icon, active = actionTexts()
		if swarmModeKey == "SATELLITES" then txt = (txt:gsub("🐶", "🛰"):gsub("ФАС!", "НА ОРБИТУ!")) end
		if ui.swLaunch then
			ui.swLaunch.Text = txt
			setBase(ui.swLaunch, active and C.danger or C.accentDark)
		end
		if ui.fireBtn then ui.fireBtn.Text = icon end
	end

	-- ---------- Бобик, фас ----------
	local function bobikCancel()
		bobikState, bobikTarget, bobikRocket = "idle", nil, nil
		for _, r in ipairs(swarmRockets) do r.atk = nil end
		setTargetFx(nil)
		setAimLocked(false)
		if ui.bark then ui.bark:Stop() end
		if ui.hintBobik then ui.hintBobik.Visible = false end
		refreshActionUi()
	end
	local function bobikPress()
		local mine = mineList()
		if #mine == 0 then notify("Нет своей ракеты", C.danger) return end
		if bobikState == "idle" then
			bobikState = "aiming"
			if ui.hintBobik then ui.hintBobik.Visible = true end
			refreshActionUi()
		elseif bobikState == "aiming" then
			local tp = pickTarget()
			if not tp then notify("Наведи кружок на игрока", C.danger) return end
			if API.selfGuard ~= false and swarmModeKey ~= "SATELLITES" then -- не запускаем, если взрыв может задеть меня
				local me, th = getHRP(), playerHRP(tp)
				if me and th and (th.Position - me.Position).Magnitude < ui.safeR.Get() + 8 then
					notify("🛡 Цель слишком близко — отойди, чтобы не задело тебя", C.danger)
					return
				end
			end
			bobikTarget, bobikT0 = tp, os.clock()
			bobikRocket = mine[1]
			for i, r in ipairs(mine) do -- все твои ракеты: подлёт → круг → рывок
				r.atk = {ph = "approach", t0 = bobikT0, t1 = bobikT0, idx = i, n = #mine}
			end
			bobikState = "attack"
			setTargetFx(tp)
			if ui.hintBobik then ui.hintBobik.Visible = false end
			if ui.bark and API.barkOn ~= false and swarmModeKey ~= "SATELLITES" then -- звук только у отправителя (SoundService)
				ui.bark.Volume = ui.barkVol and ui.barkVol.Get() or 2
				ui.bark.TimePosition = 0
				ui.bark:Play()
			end
			if swarmModeKey == "SATELLITES" then notify("🛰 Спутники на орбите: " .. tp.DisplayName)
			elseif ui.bobikBanner then ui.bobikBanner(tp.DisplayName) end
			refreshActionUi()
		else
			bobikCancel()
		end
	end

	-- ---------- катание ----------
	local function setRocketCollide(r, on)
		if on then
			if r.cc then
				for p, c in pairs(r.cc) do
					if p.Parent then p.CanCollide = c end
				end
				r.cc = nil
			end
		elseif not r.cc then
			r.cc = {}
			local list = r.obj:IsA("BasePart") and {r.obj} or {}
			for _, d in ipairs(r.obj:GetDescendants()) do
				if d:IsA("BasePart") then list[#list + 1] = d end
			end
			for _, p in ipairs(list) do
				r.cc[p] = p.CanCollide
				p.CanCollide = false
			end
		end
	end
	local function dismount()
		if not riding then return end
		riding = false
		local r = rideRocket
		rideRocket, rideTarget = nil, nil
		if r then setRocketCollide(r, true) end
		local hum = getHum()
		if hum then
			hum.Sit = false
			pcall(function() hum:ChangeState(Enum.HumanoidStateType.Jumping) end)
		end
		if ui.rideBar then ui.rideBar.Visible = false end
		refreshActionUi()
	end
	local function mount()
		local r = mineList()[1]
		local hrp, hum = getHRP(), getHum()
		if not r or not hrp or not hum then notify("Нет своей ракеты", C.danger) return end
		riding, rideRocket, rideTarget = true, r, nil
		rideHeading = flatten(camera.CFrame.LookVector)
		setRocketCollide(r, false)
		moveObj(r.obj, r.part, CFrame.new(hrp.Position - Vector3.new(0, 3.2, 0)))
		hum.Sit = true
		if ui.rideBar then ui.rideBar.Visible = touchUiOn end
		refreshActionUi()
		notify("🏄 Едем! WASD · Пробел вверх · Ctrl вниз · G — к прицелу")
	end
	local function rideGoAim()
		if not riding then return end
		rideTarget = computeAim() + Vector3.new(0, 3, 0)
		notify("🎯 Еду к точке прицела")
	end

	-- ---------- управление толпой ----------
	local function addSwarmRocket(obj, part)
		local r = {
			obj = obj, part = part, d = randomDir(), ph = math.random(),
			off = Vector2.new(math.random() * 2 - 1, math.random() * 2 - 1),
		}
		r.bv = make("BodyVelocity", {Name = "FembiixSwBV", MaxForce = Vector3.new(math.huge, math.huge, math.huge), Velocity = Vector3.zero}, part)
		r.bg = make("BodyGyro", {Name = "FembiixSwBG", MaxTorque = Vector3.new(math.huge, math.huge, math.huge), D = 150, P = 5000, CFrame = part.CFrame}, part)
		swarmRockets[#swarmRockets + 1] = r
		swarmSet[obj] = true
		r.born = os.clock()
		r.takeoff = part.Position + Vector3.new(0, 12, 0) -- при подборе взлетает вверх, не толкая тебя
	end
	local function releaseSwarmAt(idx)
		local r = table.remove(swarmRockets, idx)
		if not r then return end
		swarmSet[r.obj] = nil
		if riding and r == rideRocket then dismount() end
		r.atk = nil
		setRocketCollide(r, true)
		pcall(function() if r.fire then r.fire:Destroy() end end)
		pcall(function() r.bv:Destroy() end)
		pcall(function() r.bg:Destroy() end)
	end
	local function releaseAllSwarm()
		for i = #swarmRockets, 1, -1 do releaseSwarmAt(i) end
		aimReady = false
	end
	local function captureSwarm()
		local hrp, folder = getHRP(), getFolder()
		if not hrp or not folder then return 0 end
		local max, added = ui.swCount.Get(), 0
		for _, child in ipairs(folder:GetChildren()) do
			if #swarmRockets >= max then break end
			if child.Name == "BombMissile" and not swarmSet[child] and child ~= activeRocket then
				local part = resolvePart(child)
				if part and (part.Position - hrp.Position).Magnitude <= captureRange then
					addSwarmRocket(child, part)
					added += 1
				end
			end
		end
		if added > 0 then notify("🚀 Ракет в питомцах: +" .. added) end
		return added
	end
	local function setSwarmLaunched(on)
		if on == swarmLaunched then return end
		if on and #mineList() == 0 then notify("Нет своих ракет", C.danger) return end
		swarmLaunched = on
		swarmT0 = os.clock()
		if on then
			local A = computeAim()
			aimPoint, aimReady = A, true
			if swarmTeleport then
				local R = math.max(ui.swRadius.Get(), 4)
				for _, r in ipairs(mineList()) do
					moveObj(r.obj, r.part, CFrame.new(A + r.d * R))
				end
			end
			notify("🚀 ЗАЛП! Ракет: " .. #mineList())
		else
			notify("⏹ Толпа возвращена")
		end
		refreshActionUi()
	end
	local function setSwarmEnabled(on)
		if on == swarmEnabled then return end
		swarmEnabled = on
		if on then
			if activeRocket then cancelRocket() end
		else
			dismount()
			bobikCancel()
			setSwarmLaunched(false)
			releaseAllSwarm()
		end
		notify(on and "🐕 Режим: моя ходячая ракета" or "🕹 Режим: ручная ракета")
	end
	local function spawnRockets(count)
		if spawning then return end
		local menu = ReplicatedStorage:FindFirstChild("MenuToys")
		local rf = menu and menu:FindFirstChild("SpawnToyRemoteFunction")
		if not rf then
			notify("Не нашёл спавн-ремоут. Заспавни ракеты вручную из меню игры — питомцы их захватят", C.danger)
			return
		end
		if not getHRP() then return end
		spawning = true
		task.spawn(function()
			local okCount = 0
			for i = 1, count do
				local h = getHRP()
				if not h then break end
				local a = (i / count) * TAU
				local pos = h.Position + Vector3.new(math.cos(a) * 7, 4 + (i % 3) * 1.5, math.sin(a) * 7)
				local ok = pcall(function()
					if rf:IsA("RemoteFunction") then
						rf:InvokeServer("BombMissile", CFrame.new(pos), Vector3.zero)
					else
						rf:FireServer("BombMissile", CFrame.new(pos), Vector3.zero)
					end
				end)
				if not ok then break end
				okCount += 1
				task.wait(0.15)
			end
			task.wait(0.4)
			spawning = false
			if swarmEnabled then captureSwarm() end
			if okCount == 0 then
				notify("Спавн не сработал. Спавни вручную из меню игры", C.danger)
			else
				notify("➕ Отправлено на спавн: " .. okCount)
			end
		end)
	end

	-- раздача питомцев другим игрокам: ракета ходит за ним вместо тебя
	local function giveRocket()
		local mine = mineList()
		if #mine == 0 then notify("Нет своей ракеты для передачи", C.danger) return end
		local p = pickTarget() or nearestPlayer(80)
		if not p then notify("Наведи кружок на игрока или подойди ближе", C.danger) return end
		local r = mine[#mine]
		if riding and r == rideRocket then dismount() end
		r.atk = nil
		r.owner = p
		notify("🎁 Ракета отдана: " .. p.DisplayName)
	end
	local function takeAllBack()
		local n = 0
		for _, r in ipairs(swarmRockets) do
			if r.owner then r.owner = nil; n += 1 end
		end
		notify(n > 0 and ("↩ Забрал ракет: " .. n) or "Нечего забирать")
	end

	local function petAction()
		if not swarmEnabled then return end
		local k = modeKind()
		if k == "volley" then setSwarmLaunched(not swarmLaunched)
		elseif k == "ride" then
			if riding then dismount() else mount() end
		elseif k == "bobik" then bobikPress()
		elseif k == "dragon" then
			if #mineList() == 0 then notify("Нет ракет для дракона", C.danger) return end
			dragonBreathUntil = os.clock() + 3
			shakeUntil = os.clock() + 0.45
			notify("🔥 ОГОНЬ!")
			refreshActionUi()
		else notify("🐕 В этом режиме ракета просто гуляет за тобой") end
	end

	-- желаемая позиция ракеты i в момент t (A = точка прицела)
	local function swarmTarget(mode, r, i, N, t, A, S, R)
		local w = math.max(S, 10) / R
		if mode == "CROWD" then
			local sw = r.d:Cross(Vector3.yAxis)
			sw = (sw.Magnitude < 0.1) and Vector3.xAxis or sw.Unit
			local a = w * t + r.ph * TAU
			return A + r.d * (R * math.cos(a)) + sw * (R * 0.35 * math.sin(a * 0.7))
		elseif mode == "SINGLE" then
			return A + Vector3.new(math.cos(t * 2) * 3, math.sin(t * 3) * 1.2, math.sin(t * 2) * 3)
		elseif mode == "RING" then
			local a = t * w + i / N * TAU
			return A + Vector3.new(math.cos(a) * R, math.sin(a * 2 + t) * 1.5, math.sin(a) * R)
		elseif mode == "SPHERE" then
			local y = 1 - 2 * (i - 0.5) / N
			local rr = math.sqrt(math.max(0, 1 - y * y))
			local th = i * 2.39996 + t * w * 0.5
			return A + Vector3.new(math.cos(th) * rr, y, math.sin(th) * rr) * R
		elseif mode == "VORTEX" then
			local f = (i / N + t * 0.12) % 1
			local h = R * 0.8 * math.sin(f * TAU)
			local rad = R * (0.5 + 0.4 * math.cos(f * TAU))
			local a = t * w * 1.4 + i * 2.4
			return A + Vector3.new(math.cos(a) * rad, h, math.sin(a) * rad)
		elseif mode == "RAIN" then
			local f = (t * S / (R * 4) + r.ph) % 1
			return A + Vector3.new(r.off.X * R, R * 3 * (1 - f), r.off.Y * R)
		end
		return A
	end

	-- нос ракеты = локальная ось +Y
	local function orientRocket(r, dir, spin)
		if not r.bg.Parent then return end
		local pos = r.part.Position
		local upv = (math.abs(dir.Y) > 0.99) and Vector3.xAxis or Vector3.yAxis
		r.bg.CFrame = CFrame.lookAt(pos, pos + dir, upv) * CFrame.Angles(math.rad(-90), 0, 0) * CFrame.Angles(0, spin or 0, 0)
	end
	-- обход игрока по настоящему маршруту: если прямой путь проходит через «пузырь» вокруг тебя,
	-- цель заменяется точкой-обходом над тобой (и чуть сбоку), и ракета летит по дуге вокруг
	local function detourGoal(pos, goal, R)
		local hrp = getHRP()
		if not hrp then return goal end
		local c = hrp.Position
		local seg = goal - pos
		local len = seg.Magnitude
		if len < 0.1 then return goal end
		local dir = seg / len
		local t = math.clamp((c - pos):Dot(dir), 0, len)
		local off = (pos + dir * t) - c
		local dist = off.Magnitude
		if dist >= R then return goal end -- путь свободен
		local out = (dist > 0.3) and (off / dist) or Vector3.yAxis
		local side = out + Vector3.yAxis * 0.9
		side = (side.Magnitude > 0.1) and side.Unit or Vector3.yAxis
		return c + side * (R * 1.3)
	end
	-- если ракета всё же внутри «пузыря» — резко выдавливает наружу и вверх
	local function avoidMe(pos, v, safeR)
		local hrp = getHRP()
		if not hrp then return v end
		local rel = pos - hrp.Position
		local d = rel.Magnitude
		if d < safeR then
			local push = (d > 0.05) and (rel / d) or Vector3.yAxis
			return v + (push + Vector3.yAxis * 0.6).Unit * (safeR - d + 2) * 20
		end
		return v
	end
	local function steerRocket(r, target, ff, maxSp, gain, faceDir, spin, safeR)
		local pos = r.part.Position
		if safeR then
			local t2 = detourGoal(pos, target, safeR)
			if t2 ~= target then target, ff = t2, Vector3.zero end
		end
		local v = ff + (target - pos) * gain
		local m = v.Magnitude
		if m > maxSp then v = v * (maxSp / m); m = maxSp end
		if safeR then v = avoidMe(pos, v, safeR); m = v.Magnitude end
		if r.bv.Parent then r.bv.Velocity = v end
		if m > 3 then r.lastDir = v / m end
		orientRocket(r, faceDir or r.lastDir or Vector3.yAxis, spin)
	end

	local function followPlacement(oh, j, now) -- хвостиком за хозяином, клином
		local look = flatten(oh.CFrame.LookVector)
		local right = look:Cross(Vector3.yAxis)
		local row = math.ceil(j / 2)
		local side = (j == 1) and 0 or ((j % 2 == 0) and 1 or -1)
		local k = ui.followDist and (ui.followDist.Get() / 6) or 1
		local p = oh.Position - look * ((5 + row * 2.5) * k) + right * (side * row * 2.4)
		return Vector3.new(p.X, oh.Position.Y - 0.5 + math.sin(now * 3 + j) * 0.5, p.Z)
	end
	local function headPlacement(oh, j, size) -- башней на голове
		local head = oh.Parent and oh.Parent:FindFirstChild("Head")
		local top = (head and head.Position or (oh.Position + Vector3.new(0, 1.5, 0))) + Vector3.new(0, (head and head.Size.Y / 2 or 1) + size / 2 + 0.2, 0)
		return top + Vector3.new(0, (j - 1) * size * 0.95, 0)
	end

	local function updateRide(r, hrp, hum)
		if not hum or hum.Health <= 0 then dismount() return end
		local speed = ui.rideSpeed.Get()
		local look = camera.CFrame.LookVector
		local mv = hum.MoveDirection
		if mv.Magnitude < 0.1 then -- запасной ввод с клавиатуры
			local f = flatten(look)
			local rt = f:Cross(Vector3.yAxis)
			local m = Vector3.zero
			if UserInputService:IsKeyDown(Enum.KeyCode.W) then m += f end
			if UserInputService:IsKeyDown(Enum.KeyCode.S) then m -= f end
			if UserInputService:IsKeyDown(Enum.KeyCode.D) then m += rt end
			if UserInputService:IsKeyDown(Enum.KeyCode.A) then m -= rt end
			if m.Magnitude > 0.1 then mv = m.Unit end
		end
		local vel = Vector3.zero
		if mv.Magnitude > 0.1 then
			rideTarget = nil
			local fc = mv:Dot(flatten(look))
			vel = mv * speed + Vector3.yAxis * (look.Y * math.max(fc, 0) * speed)
		end
		if rideUp or UserInputService:IsKeyDown(Enum.KeyCode.Space) then
			vel += Vector3.yAxis * speed * 0.7
			rideTarget = nil
		end
		if rideDown or UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
			vel -= Vector3.yAxis * speed * 0.7
			rideTarget = nil
		end
		if rideTarget then
			local to = rideTarget - r.part.Position
			if to.Magnitude < 5 then
				rideTarget = nil
				notify("🏁 Приехали!")
			else
				vel = to.Unit * math.min(speed, to.Magnitude * 4)
			end
		end
		local fv = Vector3.new(vel.X, 0, vel.Z)
		if fv.Magnitude > 2 then rideHeading = fv.Unit end
		if r.bv.Parent then r.bv.Velocity = vel end
		orientRocket(r, (rideHeading + Vector3.new(0, vel.Y / math.max(speed, 1) * 0.6, 0)).Unit, 0)
	end
	local function ridePlace() -- ставим игрока на ракету сразу после физики (без дрожи камеры)
		if not riding or not rideRocket then return end
		local r = rideRocket
		local hrp, hum = getHRP(), getHum()
		if not hrp or not hum or not r.part.Parent then return end
		local rp = r.part.Position + Vector3.new(0, math.min(r.part.Size.X, r.part.Size.Z) / 2 + 2.8, 0)
		hrp.CFrame = CFrame.lookAt(rp, rp + rideHeading)
		hrp.AssemblyLinearVelocity = r.part.AssemblyLinearVelocity
		hum.Sit = true
		hum.Jump = false
	end
	connect(RunService.Heartbeat, ridePlace)
	connect(UserInputService.InputBegan, function(input, processed) -- ЛКМ по земле: ехать туда
		if not riding or processed or overGui() then return end
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			local loc = UserInputService:GetMouseLocation()
			local ray = camera:ViewportPointToRay(loc.X, loc.Y)
			local filter = {}
			if player.Character then filter[#filter + 1] = player.Character end
			local folder = getFolder()
			if folder then filter[#filter + 1] = folder end
			aimParams.FilterDescendantsInstances = filter
			local hit = workspace:Raycast(ray.Origin, ray.Direction * 1500, aimParams)
			if hit then
				rideTarget = hit.Position + Vector3.new(0, 3, 0)
				notify("📍 Еду туда, куда ты нажал")
			end
		end
	end)

	local function updateBobik(r)
		local a = r.atk
		local th = playerHRP(bobikTarget)
		local tHum = bobikTarget and bobikTarget.Character and bobikTarget.Character:FindFirstChildOfClass("Humanoid")
		local me = getHRP()
		if not a or not th or not tHum or tHum.Health <= 0 or not me or os.clock() - bobikT0 > ((swarmModeKey == "SATELLITES") and 120 or 14) then
			r.atk = nil
			return
		end
		local now = os.clock()
		local sp = ui.bobSpeed.Get()
		local safeR = ui.safeR.Get()
		local guard = (API.selfGuard ~= false) and (safeR + 8) or 0
		local tooClose = (th.Position - me.Position).Magnitude < guard
		if a.ph == "chase" and tooClose then a.ph, a.t1 = "orbit", now end -- цель рядом со мной: не бросаемся, кружим
		local pos = r.part.Position
		local v
		if swarmModeKey == "SATELLITES" then -- орбита вокруг игрока в два кольца, без атаки
			local ring = a.idx % 2
			local ang = now * (1.6 - ring * 0.5) + (a.idx - 1) * TAU / math.max(a.n, 1)
			local tilt = CFrame.Angles(math.rad(ring * 50), 0, math.rad(ring * 25))
			local goal = th.Position + tilt:VectorToWorldSpace(Vector3.new(math.cos(ang) * (9 + ring * 4), 1 + math.sin(ang * 2) * 0.5, math.sin(ang) * (9 + ring * 4)))
			v = (detourGoal(pos, goal, safeR) - pos) * 8
			if v.Magnitude > 220 then v = v.Unit * 220 end
			v = avoidMe(pos, v, safeR)
			r.lastDir = Vector3.new(-math.sin(ang), 0.1, math.cos(ang))
			if r.bv.Parent then r.bv.Velocity = v end
			orientRocket(r, r.lastDir, 0)
			return
		end
		if a.ph == "chase" then
			local dist = (th.Position - pos).Magnitude
			local lead = math.min(dist / math.max(sp, 1), 0.5)
			local wp = detourGoal(pos, th.Position + th.AssemblyLinearVelocity * lead, safeR)
			local dir = safeUnit(wp - pos, Vector3.zAxis)
			v = dir * sp
			r.lastDir = dir
			if dist < 4.5 or now - a.t1 > 12 then r.atk = nil end
		else
			local ang = now * 5 + (a.idx - 1) * (TAU / math.max(a.n, 1))
			local goal = th.Position + Vector3.new(math.cos(ang) * 11, 3 + math.sin(now * 3 + a.idx) * 1.5, math.sin(ang) * 11)
			local wp = detourGoal(pos, goal, safeR)
			local d = wp - pos
			v = d * 10
			if v.Magnitude > sp then v = v.Unit * sp end
			if a.ph == "orbit" then
				r.lastDir = Vector3.new(-math.sin(ang), 0.05, math.cos(ang))
				if now - a.t1 > 1.7 and not tooClose then a.ph, a.t1 = "chase", now end
			else
				r.lastDir = safeUnit(d, Vector3.zAxis)
				if (goal - pos).Magnitude < 9 or now - a.t0 > 8 then a.ph, a.t1 = "orbit", now end
			end
		end
		v = avoidMe(pos, v, safeR)
		-- рядом со мной летим медленнее: никакого проскока через тело
		if (pos - me.Position).Magnitude < safeR * 2 and v.Magnitude > 140 then v = v.Unit * 140 end
		if r.bv.Parent then r.bv.Velocity = v end
		orientRocket(r, (v.Magnitude > 3) and v.Unit or (r.lastDir or Vector3.yAxis), 0)
	end

	local aimCore = make("Part", {Name = "FembiixAim", Shape = Enum.PartType.Ball, Size = Vector3.new(1.2, 1.2, 1.2),
		Color = Color3.fromRGB(255, 60, 30), Material = Enum.Material.Neon, Transparency = 0.3, Anchored = true,
		CanCollide = false, CanQuery = false, CanTouch = false, CastShadow = false})
	local function hideAim()
		aimCore.Parent = nil
		if ui.aim then ui.aim.Visible = false end
	end
	local function setLbl(lbl, txt)
		if lbl and lbl.Text ~= txt then lbl.Text = txt end
	end

	-- история твоего пути (для «Эхо-хвоста»), лазеры стража, авто-шоу
	local histT, histP, histLast = {}, {}, 0
	local sentryRoot, sentryNear, autoIdx = nil, {}, 0
	local AUTO = {"CAROUSEL", "SHIELD", "HALO", "HELIX", "WINGSBACK", "GRID", "ESCORT", "CONGA", "PUPPY", "EIGHT", "DISCO"}
	local laserParts = {}
	local function laserDraw(i, a, b)
		local pt = laserParts[i]
		if not pt then
			pt = make("Part", {Name = "FembiixLaser", Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false, CastShadow = false,
				Material = Enum.Material.Neon, Color = Color3.fromRGB(255, 60, 60), Size = Vector3.new(0.12, 0.12, 1), Transparency = 0.2})
			laserParts[i] = pt
		end
		pt.Size = Vector3.new(0.12, 0.12, math.max((b - a).Magnitude, 0.1))
		pt.CFrame = CFrame.lookAt((a + b) / 2, b)
		pt.Parent = camera
	end
	local function laserHide(from)
		for i = from, #laserParts do laserParts[i].Parent = nil end
	end
	local function histAt(tt)
		local n = #histT
		if n == 0 then return nil end
		if tt >= histT[n] then return histP[n] end
		for i = n - 1, 1, -1 do
			if histT[i] <= tt then
				local f = (tt - histT[i]) / math.max(histT[i + 1] - histT[i], 1e-4)
				return histP[i]:Lerp(histP[i + 1], f)
			end
		end
		return histP[1]
	end

	-- формации питомцев → цель, направление носа, вращение, макс. скорость, радиус обхода
	local function petPlacement(mode, r, oh, j, gN, now, chain, key, camLook)
		local pos = r.part.Position
		if mode == "AUTOSHOW" then mode = AUTO[math.floor(now / 7) % #AUTO + 1] end
		if mode == "CAROUSEL" then
			local a = now * 1.5 + (j - 1) * TAU / math.max(gN, 1)
			local goal = oh.Position + Vector3.new(math.cos(a) * 7, 2.5 + math.sin(now * 2 + j * 1.7) * 1.3, math.sin(a) * 7)
			return goal, Vector3.new(-math.sin(a), 0.12 * math.cos(now * 2 + j), math.cos(a)).Unit, 0, 260, nil
		elseif mode == "CONGA" then
			local wig = oh.CFrame.RightVector * (math.sin(now * 5 - j * 1.2) * 1.6) + Vector3.new(0, math.sin(now * 3 - j) * 0.5, 0)
			local prev = chain[key]
			local goal
			if not prev then
				goal = oh.Position - oh.CFrame.LookVector * 3.8 + Vector3.new(0, 1.8, 0) + wig
			else
				local d = pos - prev
				d = (d.Magnitude > 0.1) and d.Unit or -oh.CFrame.LookVector
				goal = prev + d * 4.2 + wig
			end
			local toward = (prev or oh.Position) - pos
			chain[key] = pos
			return goal, (toward.Magnitude > 0.5) and toward.Unit or camLook, 0, 240, nil
		elseif mode == "PUPPY" then
			local base = followPlacement(oh, j, now)
			local ph = r.ph * 6.28
			local goal = base + Vector3.new(math.sin(now * 1.3 + ph) * 2.5, math.abs(math.sin(now * 3.2 + ph)) * 4, math.cos(now * 1.1 + ph) * 2)
			local flipT = (now + r.ph * 6) % 4
			local ang = (flipT < 0.8) and (flipT / 0.8 * TAU) or 0
			local lk = CFrame.new(Vector3.zero, camLook) * CFrame.Angles(-ang, math.sin(now * 9 + ph) * 0.5, 0)
			return goal, lk.LookVector, 0, 200, nil
		elseif mode == "SHIELD" then
			local a = now * 3 + (j - 1) * TAU / math.max(gN, 1)
			local rot = CFrame.Angles(0, now * 0.9, math.rad(65))
			local goal = oh.Position + rot:VectorToWorldSpace(Vector3.new(math.cos(a) * 5.5, math.sin(a) * 5.5, 0))
			return goal, rot:VectorToWorldSpace(Vector3.new(-math.sin(a), math.cos(a), 0)).Unit, 0, 320, nil
		elseif mode == "ESCORT" then
			local look = flatten(oh.CFrame.LookVector)
			local right = look:Cross(Vector3.yAxis)
			local row = math.ceil(j / 2)
			local side = (j % 2 == 0) and 1 or -1
			local goal = oh.Position - look * (1.5 + row * 2.4) + right * (side * (3.2 + row * 2.2)) + Vector3.new(0, 1 + math.sin(now * 4 + j) * 0.8, 0)
			return goal, (look + Vector3.new(0, 0.08, 0)).Unit, 0, 240, nil
		end
		if mode == "ECHO" then
			local d = j * 0.8 + 0.3
			local p0 = histAt(now - d) or oh.Position
			local p1 = histAt(now - d - 0.15) or p0
			local fv = p0 - p1
			return p0 + Vector3.new(0, 1.2 + math.sin(now * 3 + j) * 0.3, 0), (fv.Magnitude > 0.05) and fv.Unit or camLook, 0, 300, nil
		elseif mode == "SENTRY" then
			local a = (j - 1) * TAU / math.max(gN, 1) + math.pi / 4
			local goal = oh.Position + Vector3.new(math.cos(a) * 4.5, 4.2 + math.sin(now * 2 + j) * 0.3, math.sin(a) * 4.5)
			local face = Vector3.yAxis
			if sentryRoot then
				local dv = sentryRoot.Position - goal
				if dv.Magnitude > 0.5 then face = dv.Unit end
			end
			return goal, face, 0, 240, nil
		elseif mode == "DISCO" then
			local b = math.abs(math.sin(now * math.pi * 2))
			local a = now * 2.2 + (j - 1) * TAU / math.max(gN, 1)
			local rad = 5 + 3 * b
			local y = 3 + ((j % 2 == 0) and b or (1 - b)) * 3
			return oh.Position + Vector3.new(math.cos(a) * rad, y, math.sin(a) * rad), Vector3.new(-math.sin(a), 0.3 * (b - 0.5), math.cos(a)).Unit, now * 10, 300, nil
		elseif mode == "HALO" then
			local a = now * 2 + (j - 1) * TAU / math.max(gN, 1)
			return oh.Position + Vector3.new(math.cos(a) * 3.2, 5.2 + math.sin(now * 3 + j) * 0.3, math.sin(a) * 3.2), Vector3.new(-math.sin(a), 0, math.cos(a)), 0, 280, nil
		elseif mode == "HELIX" then
			local a = now * 2.2 + j * 0.9
			local h = ((j - 1) / math.max(gN, 1)) * 12
			return oh.Position + Vector3.new(math.cos(a) * 4.5, -1 + h, math.sin(a) * 4.5), Vector3.new(-math.sin(a), 0.6, math.cos(a)).Unit, 0, 300, nil
		elseif mode == "WINGSBACK" then
			local side = (j % 2 == 0) and 1 or -1
			local kk = math.ceil(j / 2)
			local flap = math.sin(now * 3) * 0.45
			local off = Vector3.new(side * (2.4 + kk * 2.3 * math.cos(0.45 + flap)), 1.2 + kk * 1.7 * math.sin(0.45 + flap), 2.4 + kk * 0.5)
			local cf = oh.CFrame
			return cf:PointToWorldSpace(off), cf:VectorToWorldSpace(Vector3.new(side * 0.5, 1, 0.2)).Unit, 0, 280, nil
		elseif mode == "GRID" then
			local col, rowi = (j - 1) % 3, math.floor((j - 1) / 3)
			local off = Vector3.new((col - 1) * 3.4, 1.5 + rowi * 3.2 + math.sin(now * 2 + col + rowi) * 0.4, -9)
			return oh.CFrame:PointToWorldSpace(off), Vector3.yAxis, 0, 240, nil
		elseif mode == "EIGHT" then
			local function pt(a)
				local dd = 1 + math.sin(a) ^ 2
				return Vector3.new(7 * math.cos(a) / dd, 2 + math.sin(now + j) * 0.5, 14 * math.sin(a) * math.cos(a) / dd)
			end
			local a = now * 1.2 + (j - 1) * TAU / math.max(gN, 1)
			local p0, p1 = pt(a), pt(a + 0.05)
			return oh.Position + p0, (p1 - p0).Unit, 0, 300, nil
		end
		-- FOLLOW и все остальные режимы: идут хвостиком, обходят игрока
		local v = r.part.AssemblyLinearVelocity
		return followPlacement(oh, j, now), (Vector3.yAxis + Vector3.new(v.X, 0, v.Z) * 0.03).Unit, now * 1.2 + j, 220, 4.2
	end

	-- ---------- ДРАКОН ----------
	local function camRelease()
		if camOwned then
			camOwned, camPos = false, nil
			camera.CameraType = Enum.CameraType.Custom
			local h = getHum()
			if h then camera.CameraSubject = h end
		end
	end
	local function ensureFire(r, isHead)
		if r.fire and r.fireHead == isHead then return end
		if r.fire then r.fire:Destroy() end
		r.fireHead = isHead
		local props = {
			Name = "FembiixFire", Rate = 0, LightEmission = 1, Rotation = NumberRange.new(0, 360), RotSpeed = NumberRange.new(-120, 120),
			Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 240, 160)), ColorSequenceKeypoint.new(0.4, Color3.fromRGB(255, 140, 20)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(120, 20, 0))}),
			Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(1, 1)}),
		}
		if isHead then -- пламя вылетает из носа ракеты вперёд
			props.Lifetime = NumberRange.new(0.35, 0.8)
			props.Speed = NumberRange.new(30, 55)
			props.SpreadAngle = Vector2.new(14, 14)
			props.Acceleration = Vector3.new(0, 4, 0)
			props.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 1.5), NumberSequenceKeypoint.new(1, 5)})
		else -- тлеющие искры по телу
			props.Lifetime = NumberRange.new(0.4, 0.9)
			props.Speed = NumberRange.new(2, 7)
			props.SpreadAngle = Vector2.new(180, 180)
			props.Acceleration = Vector3.new(0, 6, 0)
			props.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.7), NumberSequenceKeypoint.new(1, 0)})
		end
		r.fire = make("ParticleEmitter", props, r.part)
	end
	local function dragonUpdate(list, hrp, now, hunt)
		local S = math.max(ui.swSpeed.Get(), 40)
		local safeR = ui.safeR.Get()
		local br = (now < dragonBreathUntil) and math.min((dragonBreathUntil - now) * 3, 1) or 0
		local head = list[1]
		local goal
		if hunt then
			goal = aimPoint + Vector3.new(math.cos(now * 1.3) * 10, 7 + math.sin(now * 2) * 3, math.sin(now * 1.7) * 10)
		else
			local a = now * 0.55
			goal = hrp.Position + Vector3.new(math.cos(a) * 30, 24 + math.sin(now * 0.8) * 7, math.sin(a) * 30)
		end
		steerRocket(head, goal, Vector3.zero, S, 3, nil, 0, safeR)
		dragonFwd = head.lastDir or dragonFwd
		ensureFire(head, true)
		head.fire.Rate = 40 + 360 * br
		local size = math.max(head.part.Size.X, head.part.Size.Y, head.part.Size.Z)
		local spacing = math.clamp(size * 0.85, 2.5, 6)
		for i = 2, #list do
			local r = list[i]
			local prev = list[i - 1].part.Position
			local cur = r.part.Position
			local d = cur - prev
			d = (d.Magnitude > 0.1) and d.Unit or -dragonFwd
			local perp = d:Cross(Vector3.yAxis)
			perp = (perp.Magnitude > 0.1) and perp.Unit or Vector3.xAxis
			local wave = perp * (math.sin(now * 4 - i * 0.7) * 1.4) + Vector3.new(0, math.cos(now * 3.1 - i * 0.6) * 0.9, 0)
			local face = prev - cur
			face = (face.Magnitude > 0.1) and face.Unit or dragonFwd
			steerRocket(r, prev + d * spacing + wave, Vector3.zero, S * 2, 14, face, 0, safeR)
			ensureFire(r, false)
			r.fire.Rate = 10 + 40 * br
		end
	end

	local aimScr = nil
	local function swarmStep(dt, now)
		for i = #swarmRockets, 1, -1 do
			local r = swarmRockets[i]
			if not r.part.Parent or not r.part:IsDescendantOf(workspace) then
				releaseSwarmAt(i)
			elseif r.owner and not r.owner.Parent then
				r.owner = nil
			end
		end
		local kind = modeKind()
		local mine = mineList()
		if ui.fireBtn then
			ui.fireBtn.Visible = touchUiOn and swarmEnabled and not introActive and kind ~= "pet" and #mine > 0
		end
		if not swarmEnabled then
			hideAim()
			aimReady = false
			setLbl(ui.swStatus, "Питомец выключен · открой вкладку «Моя ракета»")
			camRelease()
			laserHide(1)
			dragonOn = false
			return
		end
		local hrp, hum = getHRP(), getHum()
		if not hrp then return end

		local maxN = ui.swCount.Get()
		while #swarmRockets > maxN do releaseSwarmAt(#swarmRockets) end
		swarmCapTimer -= dt
		if swarmAuto and swarmCapTimer <= 0 and #swarmRockets < maxN then
			swarmCapTimer = 0.4
			captureSwarm()
		end

		local N = #swarmRockets
		mine = mineList()
		setLbl(ui.swStatus, ("Ракет: %d/%d · твоих %d · отдано %d"):format(N, maxN, #mine, N - #mine))
		if N == 0 then
			hideAim()
			aimReady = false
			aimScr = nil
			if swarmLaunched then swarmLaunched = false; refreshActionUi() end
			camRelease()
			laserHide(1)
			dragonOn = false
			return
		end

		-- прицел
		local needRay = (kind == "volley") or (kind == "ride") or (kind == "dragon" and swarmModeKey == "DRAGON")
		if needRay then
			local A = (camOwned and dragonOn) and (hrp.Position + flatten(hrp.CFrame.LookVector) * 45 + Vector3.new(0, 8, 0)) or computeAim()
			if not aimReady then aimPoint, aimReady = A, true
			else aimPoint = aimPoint:Lerp(A, math.clamp(dt * 18, 0, 1)) end
		end
		local aiming = (kind == "bobik" and bobikState == "aiming")
		local shown = nil
		if aiming then
			shown = pickTarget()
			setTargetFx(shown)
			setAimLocked(shown ~= nil)
		elseif kind == "bobik" and bobikState == "attack" then
			shown = bobikTarget
		end
		local showMarker = (kind == "volley") or (kind == "ride" and rideTarget ~= nil) or (kind == "dragon" and swarmModeKey == "DRAGON")
		if showMarker then
			local pulse = 1 + 0.2 * math.sin(now * 8)
			aimCore.Size = Vector3.new(1.2, 1.2, 1.2) * pulse
			aimCore.CFrame = CFrame.new((kind == "ride") and rideTarget or aimPoint)
			aimCore.Parent = camera
		else
			aimCore.Parent = nil
		end
		if ui.aim then
			local show = needRay or aiming or shown ~= nil
			ui.aim.Visible = show
			if show then
				local vs = camera.ViewportSize
				local want = Vector2.new(vs.X / 2, vs.Y / 2)
				local sr = shown and playerHRP(shown)
				if sr then -- кружок «прилипает» к игроку
					local sp, on = camera:WorldToViewportPoint(sr.Position)
					if on and sp.Z > 0 then want = Vector2.new(sp.X, sp.Y) end
				end
				aimScr = (aimScr or want):Lerp(want, math.clamp(dt * 16, 0, 1))
				ui.aim.Position = UDim2.fromOffset(aimScr.X, aimScr.Y)
				local s = ((shown and 70) or (aiming and 44) or 34) + 4 * math.sin(now * 6)
				ui.aim.Size = UDim2.new(0, s, 0, s)
				if ui.aimLabel then
					ui.aimLabel.Text = shown and ((bobikState == "attack" and "💥 " or "🎯 ") .. shown.DisplayName .. (bobikState ~= "attack" and "  •  жми F" or "")) or ""
				end
			else
				aimScr = nil
			end
		end

		dragonOn = false
		if kind == "dragon" then
			local list = {}
			for _, r in ipairs(mine) do
				if now - (r.born or 0) >= 0.7 then list[#list + 1] = r end
			end
			if #list > 0 then
				dragonOn, dragonList = true, list
				dragonUpdate(list, hrp, now, swarmModeKey == "DRAGON")
				for _, r in ipairs(list) do r.dgNow = now end
			end
		end

		local S, R = ui.swSpeed.Get(), math.max(ui.swRadius.Get(), 4)
		local t = now - swarmT0
		local camLook = camera.CFrame.LookVector
		if now - histLast > 0.04 then -- история пути для «Эхо-хвоста»
			histLast = now
			histT[#histT + 1], histP[#histP + 1] = now, hrp.Position
			if #histT > 320 then table.remove(histT, 1); table.remove(histP, 1) end
		end
		if swarmModeKey == "AUTOSHOW" then
			local ai = math.floor(now / 7) % #AUTO + 1
			if ai ~= autoIdx then autoIdx = ai; notify("🎬 Формация: " .. AUTO[ai]) end
		end
		sentryRoot = nil
		if swarmModeKey == "SENTRY" then
			local sp = nearestPlayer(150)
			sentryRoot = sp and playerHRP(sp) or nil
			if sp and sentryRoot and (sentryRoot.Position - hrp.Position).Magnitude < 40 and (sentryNear[sp] or 0) < now - 10 then
				sentryNear[sp] = now
				notify("⚠ Рядом игрок: " .. sp.DisplayName)
			end
		end
		local lasersUsed = 0
		local groupCount, chain = {}, {}
		for _, r in ipairs(swarmRockets) do
			local key = r.owner or "me"
			groupCount[key] = (groupCount[key] or 0) + 1
			r.gi = groupCount[key]
		end
		for _, r in ipairs(swarmRockets) do
			local isMine = not r.owner
			local key = r.owner or "me"
			-- коллизии: питомцы не толкают тебя; в атаке коллизии включены, но траектория огибает игрока
			local attackingNow = isMine and ((kind == "bobik" and r.atk ~= nil) or (kind == "volley" and swarmLaunched))
			local wantOff = (API.noPush ~= false) and not attackingNow
			if riding and r == rideRocket then wantOff = true end
			if (r.cc ~= nil) ~= wantOff then setRocketCollide(r, not wantOff) end
			if r.fire and (kind ~= "dragon" or not isMine) then r.fire:Destroy(); r.fire = nil end

			if isMine and riding and r == rideRocket then
				updateRide(r, hrp, hum)
			elseif isMine and kind == "bobik" and bobikState == "attack" and r.atk then
				updateBobik(r)
			elseif isMine and kind == "dragon" and r.dgNow == now then
				-- этой ракетой уже управляет дракон
			elseif isMine and kind == "volley" and swarmLaunched and (swarmModeKey ~= "SINGLE" or r == mine[1]) then
				local M = #mine
				local p0 = swarmTarget(swarmModeKey, r, r.gi, M, t, aimPoint, S, R)
				local p1 = swarmTarget(swarmModeKey, r, r.gi, M, t + 0.05, aimPoint, S, R)
				steerRocket(r, p0, (p1 - p0) / 0.05, math.max(S, 30) * 1.6, 5, nil, nil, ui.safeR.Get())
			else
				local oh = (r.owner and playerHRP(r.owner)) or hrp
				local mode = isMine and swarmModeKey or "FOLLOW"
				local target, face, spin, maxBase, safeR
				if now - (r.born or 0) < 0.7 then
					target, face, spin, maxBase, safeR = r.takeoff, Vector3.yAxis, 0, 70, nil
				elseif mode == "HEAD" then
					local sz = math.max(r.part.Size.X, r.part.Size.Y, r.part.Size.Z)
					target, face, spin, maxBase, safeR = headPlacement(oh, r.gi, sz), Vector3.yAxis, now * 2, 160, nil
				else
					target, face, spin, maxBase, safeR = petPlacement(mode, r, oh, r.gi, groupCount[key], now, chain, key, camLook)
				end
				local dist = (target - r.part.Position).Magnitude
				if dist > 150 then moveObj(r.obj, r.part, CFrame.new(target)) end
				steerRocket(r, target, Vector3.zero, math.clamp(dist * 5, 25, maxBase), 5, face, spin, safeR)
				if mode == "SENTRY" and sentryRoot then
					lasersUsed += 1
					laserDraw(lasersUsed, r.part.Position + face * 1.5, sentryRoot.Position)
				end
			end
		end

		laserHide(lasersUsed + 1)
		-- дракон: кино-камера, тряска при дыхании, обновление кнопки
		local breathing = dragonOn and now < dragonBreathUntil
		if breathing ~= breathWas then breathWas = breathing; refreshActionUi() end
		if dragonOn and API.dragonCam == true then
			camera.CameraType = Enum.CameraType.Scriptable
			camOwned = true
			local head, tail = dragonList[1].part.Position, dragonList[#dragonList].part.Position
			local mid = (head + tail) / 2
			local len = (head - tail).Magnitude
			local want = mid + CFrame.Angles(0, now * 0.3, 0):VectorToWorldSpace(Vector3.new(0, 8 + len * 0.25, 22 + len * 0.7))
			camPos = (camPos or want):Lerp(want, math.clamp(dt * 3, 0, 1))
			camera.CFrame = CFrame.lookAt(camPos, mid + Vector3.new(0, 2, 0))
		elseif camOwned then
			camRelease()
		end
		if shakeUntil > now and not camOwned then
			local amp = (shakeUntil - now) / 0.45 * 0.7
			camera.CFrame = camera.CFrame * CFrame.new((math.random() - 0.5) * amp, (math.random() - 0.5) * amp, 0)
		end

		-- атака закончена, когда ни у одной ракеты не осталось задания
		if kind == "bobik" and bobikState == "attack" then
			local any = false
			for _, r in ipairs(swarmRockets) do
				if r.atk then any = true break end
			end
			if not any then
				local nm = bobikTarget and bobikTarget.DisplayName or "?"
				bobikCancel()
				notify("💥 Бобик закончил: " .. nm)
			end
		end
	end

	API.camRelease = camRelease
	API.laserClear = function()
		laserHide(1)
		for _, pt in ipairs(laserParts) do pt:Destroy() end
		laserParts = {}
	end
	function API.dragonInfo() -- для языков пламени у спаркеров
		if not dragonOn or not dragonList[1] or not dragonList[1].part.Parent then return nil end
		local now = os.clock()
		local b = (now < dragonBreathUntil) and math.min((dragonBreathUntil - now) * 3, 1) or 0
		return {head = dragonList[1].part.Position, fwd = dragonFwd, breath = b}
	end
	function API.dragonSparkPos(i, N, now) -- позиции спаркеров: глаза, гребень, пламя
		if not dragonOn or #dragonList == 0 or not dragonList[1].part.Parent then return nil end
		local head = dragonList[1].part.Position
		local fwd = dragonFwd
		local right = fwd:Cross(Vector3.yAxis)
		right = (right.Magnitude > 0.1) and right.Unit or Vector3.xAxis
		if i <= 2 then
			return head + fwd * 1.2 + Vector3.new(0, 1.0, 0) + right * ((i == 1) and -0.9 or 0.9)
		end
		if now < dragonBreathUntil then
			local u = (now * 1.6 + i * 0.37) % 1
			local w = now * 3 + i * 1.7
			local n = Vector3.new(math.noise(w, 0.3, 0), math.noise(w, 4.1, 0), math.noise(w, 8.9, 0))
			return head + fwd * (4 + u * 18) + n * (u * 8)
		end
		local idx = math.min(((i - 3) % math.max(#dragonList - 1, 1)) + 2, #dragonList)
		return dragonList[idx].part.Position + Vector3.new(0, 2 + math.sin(now * 6 + i) * 0.6, 0)
	end
	API.noPush = true
	API.petAction = petAction
	API.rideGoAim = rideGoAim
	API.dismount = dismount
	API.bobikCancel = bobikCancel
	API.setSwarmEnabled = setSwarmEnabled
	API.setSwarmLaunched = setSwarmLaunched
	API.captureSwarm = captureSwarm
	API.spawnRockets = spawnRockets
	API.giveRocket = giveRocket
	API.takeAllBack = takeAllBack
	API.releaseAllSwarm = releaseAllSwarm
	API.refreshActionUi = refreshActionUi
	API.swarmStep = swarmStep
	API.isRiding = function() return riding end
	API.bobikBusy = function() return bobikState ~= "idle" end
	API.rideHold = function(which, v)
		if which == "up" then rideUp = v else rideDown = v end
	end
end

-- ============================ КОРОБКИ: ОТКЛЮЧЕНО ============================
do
	API.boxStep = function() end
	API.releaseAllBoxes = function() end
	function API.onKey(code) -- общий обработчик клавиш F / G / X
		if code == Enum.KeyCode.F then
			if API.bananaRunning and API.bananaRunning() then API.bananaStop() return true end
			if swarmEnabled then API.petAction() else return false end
			return true
		elseif code == Enum.KeyCode.G and API.isRiding() then
			API.rideGoAim()
			return true
		elseif code == Enum.KeyCode.X and API.bobikBusy() then
			API.bobikCancel()
			return true
		end
		return false
	end
end

-- ============================ ФАЙРВОРК-СПАРКЛЕРЫ ============================
local STAR_ORDER = {0, 2, 4, 1, 3}
local GRAY = {0, 1, 3, 2, 6, 7, 5, 4} -- обход вершин куба по рёбрам

-- каркасные линии (светящиеся рёбра с искрами)
local wire = {pool = {}, used = 0}
local function wireLine(a, b, color, thick, sparks)
	wire.used += 1
	local e = wire.pool[wire.used]
	if not e then
		local p = make("Part", {Name = "FembiixWire", Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false,
			CastShadow = false, Material = Enum.Material.Neon, Color = SPARK_C1, Size = Vector3.new(0.12, 0.12, 1)})
		local pe = make("ParticleEmitter", {
			Rate = 0, Lifetime = NumberRange.new(0.3, 0.8), Speed = NumberRange.new(0.5, 3),
			SpreadAngle = Vector2.new(180, 180), LightEmission = 1, Acceleration = Vector3.new(0, -8, 0),
			Shape = Enum.ParticleEmitterShape.Box, ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume,
			Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 0)}),
			Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1)}),
			Color = ColorSequence.new(SPARK_C1, SPARK_C2),
		}, p)
		e = {part = p, pe = pe}
		wire.pool[wire.used] = e
	end
	local len = math.max((b - a).Magnitude, 0.05)
	e.part.Size = Vector3.new(thick, thick, len)
	e.part.CFrame = CFrame.lookAt((a + b) / 2, b)
	e.part.Color = color
	e.part.Transparency = 0.1 + 0.3 * math.random()
	e.pe.Rate = (sparks and sparkFx) and len * 2.5 or 0
	e.pe.Color = ColorSequence.new(color, SPARK_C2)
	e.part.Parent = camera
end
local function wireEnd()
	for i = wire.used + 1, #wire.pool do wire.pool[i].part.Parent = nil end
end
local function wireClear()
	wire.used = 0
	wireEnd()
end
local function wireColor(now)
	if sparkRainbow then return Color3.fromHSV((now * 0.1) % 1, 0.55, 1) end
	return SPARK_C1
end

-- куб
local function cubeBasis(t, W)
	return CFrame.Angles(t * W * 0.22, t * W * 0.37, 0) * CFrame.Angles(math.rad(35), 0, math.rad(45))
end
local function cubeCorner(ci, rot, R, H)
	local x = (ci % 2 == 0) and -1 or 1
	local y = (math.floor(ci / 2) % 2 == 0) and -1 or 1
	local z = (math.floor(ci / 4) % 2 == 0) and -1 or 1
	return rot:VectorToWorldSpace(Vector3.new(x, y, z) * (R * 0.5)) + Vector3.new(0, H + R * 0.55 + 1.5, 0)
end
local function cubeRunner(u, rot, R, H) -- u в [0, 8): бег по вершинам вдоль рёбер
	local seg = math.floor(u) % 8
	local fr = u - math.floor(u)
	local a = cubeCorner(GRAY[seg + 1], rot, R, H)
	local b = cubeCorner(GRAY[(seg + 1) % 8 + 1], rot, R, H)
	return a:Lerp(b, fr)
end

-- пентаграмма
local function starVertex(idx, t, R, H)
	local a = STAR_ORDER[(idx % 5) + 1] * TAU / 5 + t * 0.4
	return Vector3.new(math.sin(a) * R, -2.2 + H * 0.25, -math.cos(a) * R)
end

-- пирамида: вершина 0 = верх, 1..4 = основание
TXT.PYR_ORDER = {1, 2, 3, 4, 0}
function TXT.pyrVert(i, t, R, H, W)
	local c = Vector3.new(0, H + R * 0.2 + 1.5, 0)
	if i == 0 then return c + Vector3.new(0, R * 0.95, 0) end
	local rot = CFrame.Angles(0, t * W * 0.5, 0)
	local a = (i - 1) * math.pi / 2 + math.pi / 4
	return c + rot:VectorToWorldSpace(Vector3.new(math.cos(a), 0, math.sin(a)) * R * 0.75)
end
function TXT.pyrRun(u, t, R, H, W)
	local seg = math.floor(u) % 5
	local fr = u - math.floor(u)
	return TXT.pyrVert(TXT.PYR_ORDER[seg + 1], t, R, H, W):Lerp(TXT.pyrVert(TXT.PYR_ORDER[(seg + 1) % 5 + 1], t, R, H, W), fr)
end

-- локальные оффсеты: +X вправо, +Y вверх, -Z вперёд (+Z за спину)
local function sparkOffset(mode, i, N, t, R, H, W)
	local k = i - 1

	if mode == "HEART" then
		local a = k / N * TAU + t * W * 0.15
		local s = R / 16 * (1 + 0.07 * math.sin(t * 6))
		local hx = 16 * math.sin(a) ^ 3
		local hy = 13 * math.cos(a) - 5 * math.cos(2 * a) - 2 * math.cos(3 * a) - math.cos(4 * a)
		local sway = math.sin(t * 0.8) * 0.35
		local x = hx * s
		return Vector3.new(x * math.cos(sway), hy * s + H + R * 0.5, R * 0.5 + 3 + x * math.sin(sway))

	elseif mode == "CIRCLE" then
		local a = k / N * TAU + t * W
		return Vector3.new(math.cos(a) * R, H + math.sin(a * 3 + t * 2) * 0.7, math.sin(a) * R)

	elseif mode == "CUBE" then
		local rot = cubeBasis(t, W)
		if N >= 8 then
			if k < 8 then return cubeCorner(GRAY[k + 1], rot, R, H) end
			return cubeRunner(t * W * 0.9 + (k - 8) / (N - 8) * 8, rot, R, H)
		end
		return cubeRunner(t * W * 0.9 + k / N * 8, rot, R, H)

	elseif mode == "TORNADO" then
		local f = (k / N + t * 0.09 * W) % 1
		local y = H - 2 + f * (R * 1.3 + 3)
		local r = R * (0.25 + 0.75 * f)
		local a = t * W * 1.5 + k * 2.4 + f * 3
		return Vector3.new(math.cos(a) * r, y, math.sin(a) * r)

	elseif mode == "BLACKHOLE" then
		local f = (k / N + t * 0.08 * W) % 1
		local r = R * (1 - f) + 0.6
		local a = k / N * TAU + t * W + f * f * 6
		local x, z0 = math.cos(a) * r, math.sin(a) * r
		return Vector3.new(x, H + 2 + z0 * 0.4, -(R * 1.2 + 2) + z0 * 0.92)

	elseif mode == "DNA" then
		local strand = k % 2
		local idx = math.floor(k / 2)
		local cnt = math.ceil(N / 2)
		local y = H - 2 + idx / math.max(cnt - 1, 1) * (R * 1.2 + 2)
		local a = t * W + strand * math.pi + y * 0.6
		local r = R * 0.45 + 1
		return Vector3.new(math.cos(a) * r, y, math.sin(a) * r)

	elseif mode == "ATOM" then
		local ring = k % 3
		local idx = math.floor(k / 3)
		local cnt = math.floor((N - 1 - ring) / 3) + 1
		local a = idx / math.max(cnt, 1) * TAU + t * W * (1 + ring * 0.35)
		local p = Vector3.new(math.cos(a) * R, math.sin(a) * R, 0)
		local rot = CFrame.Angles(0, ring * math.pi / 3 + t * 0.3, 0)
		return rot:VectorToWorldSpace(p) + Vector3.new(0, H + R * 0.8, 0)

	elseif mode == "PENTAGRAM" then
		local s = (k / N + t * 0.03 * W) % 1
		local seg = math.floor(s * 5)
		local fr = s * 5 - seg
		return starVertex(seg, t, R, H):Lerp(starVertex(seg + 1, t, R, H), fr)

	elseif mode == "WINGS" then
		local side = (k % 2 == 0) and 1 or -1
		local j = math.floor(k / 2) + 1
		local K = math.ceil(N / 2)
		local u = j / K
		local flap = 0.25 + 0.5 * math.sin(t * W * 1.6)
		local x = 1.0 + u * R * 0.9
		local y = math.sin(u * 2.3) * R * 0.55
		local rx = x * math.cos(flap) - y * math.sin(flap)
		local ry = x * math.sin(flap) + y * math.cos(flap)
		return Vector3.new(side * rx, ry + H * 0.4 + 1.2, 1.8 + u * 0.6)

	elseif mode == "SPHERE" then
		local y = 1 - 2 * (k + 0.5) / N
		local rr = math.sqrt(math.max(0, 1 - y * y))
		local th = k * 2.39996 + t * W * 0.6
		local v = Vector3.new(math.cos(th) * rr, y, math.sin(th) * rr) * (R * 0.6)
		return CFrame.Angles(t * 0.25, 0, t * 0.15):VectorToWorldSpace(v) + Vector3.new(0, H + R * 0.55 + 2, 0)

	elseif mode == "INFINITY" then
		local a = k / N * TAU + t * W * 0.7
		local d = 1 + math.sin(a) ^ 2
		return Vector3.new(R * 1.3 * math.cos(a) / d, H + R * 0.5 + 3 + math.sin(a * 2) * 1.2, R * 1.3 * math.sin(a) * math.cos(a) / d)

	elseif mode == "COMET" then
		local a = t * W * 0.9 - k * 0.22
		local rr = R * (1 - k / math.max(N, 1) * 0.3)
		local p = Vector3.new(math.cos(a) * rr, math.sin(a * 2 + t) * 1.5, math.sin(a) * rr)
		return CFrame.Angles(0, 0, math.rad(28)):VectorToWorldSpace(p) + Vector3.new(0, H + R * 0.45 + 1, 0)

	elseif mode == "WAVE" then
		local u = k / math.max(N - 1, 1) - 0.5
		return Vector3.new(u * R * 2.4, H + 1 + math.sin(t * W * 1.4 + k * 0.9) * (R * 0.35), -(R * 0.8) + math.cos(t * W * 0.9 + k * 0.6) * 2)
	end
	if mode == "PYRAMID" then
		if N >= 5 then
			if k < 5 then return TXT.pyrVert(k, t, R, H, W) end
			return TXT.pyrRun(t * W * 0.8 + (k - 5) / (N - 5) * 5, t, R, H, W)
		end
		return TXT.pyrRun(t * W * 0.8 + k / N * 5, t, R, H, W)

	elseif mode == "GALAXY" then
		local arm = k % 3
		local f = (math.floor(k / 3) + 1) / (math.ceil(N / 3) + 0.5)
		local a = arm * TAU / 3 + f * 3.2 + t * W * 0.5 * (1.3 - f)
		local r = R * (0.25 + 0.9 * f)
		return Vector3.new(math.cos(a) * r, H + 3 + math.sin(t * 2 + k) * 0.5, math.sin(a) * r)

	elseif mode == "FIREWORK" then
		local y = 1 - 2 * (k + 0.5) / N
		local rr = math.sqrt(math.max(0, 1 - y * y))
		local th = k * 2.39996
		local d = Vector3.new(math.cos(th) * rr, y, math.sin(th) * rr)
		local c = Vector3.new(0, H + R * 0.9 + 2, -R * 0.9)
		local p = (t / 3.2) % 1
		if p < 0.55 then
			local b = easeOutCubic(p / 0.55)
			return c + d * (R * 1.5 * b) - Vector3.new(0, (p / 0.55) ^ 2 * R * 0.5, 0)
		elseif p < 0.85 then
			return c + d * (R * 1.5) - Vector3.new(0, R * 0.5 + (p - 0.55) * R * 0.6, 0)
		end
		local far = c + d * (R * 1.5) - Vector3.new(0, R * 0.5 + 0.3 * R * 0.6, 0)
		return far:Lerp(c, easeOutCubic((p - 0.85) / 0.15))

	elseif mode == "ORBITS" then
		local r = R * (0.4 + 0.18 * k)
		local a = t * W * (1.7 - 0.09 * k) + k * 1.3
		local rot = CFrame.Angles(k * 0.5, k * 0.9, 0)
		return rot:VectorToWorldSpace(Vector3.new(math.cos(a) * r, 0, math.sin(a) * r)) + Vector3.new(0, H + 2, 0)

	elseif mode == "CROWN" then
		local a = k / N * TAU + t * W * 0.4
		local spike = (k % 2 == 0) and R * 0.4 or 0
		return Vector3.new(math.cos(a) * R * 0.55, H + 3.5 + spike, math.sin(a) * R * 0.55)

	elseif mode == "TREFOIL" then
		local a = t * W * 0.5 + k / N * TAU
		local s = R / 3.2
		local pt = Vector3.new((math.sin(a) + 2 * math.sin(2 * a)) * s, (math.cos(a) - 2 * math.cos(2 * a)) * s * 0.8, -math.sin(3 * a) * s)
		return CFrame.Angles(t * 0.2, t * 0.3, 0):VectorToWorldSpace(pt) + Vector3.new(0, H + R * 0.8 + 2, 0)

	elseif mode == "SPIROGRAPH" then
		local a, q = t * W * 0.5 + k * 0.6, 0.31
		local hx = (1 - q) * math.cos(a) + 0.9 * q * math.cos((1 - q) / q * a)
		local hy = (1 - q) * math.sin(a) - 0.9 * q * math.sin((1 - q) / q * a)
		return Vector3.new(hx * R * 1.1, H + R * 0.8 + 3 + hy * R * 1.1, -R * 1.2)

	elseif mode == "LISSAJOUS" then
		local a = t * W * 0.4 + k * 0.7
		return Vector3.new(math.sin(3 * a + math.pi / 2) * R, H + R * 0.6 + 3 + math.sin(2 * a) * R * 0.6, math.sin(5 * a) * R * 0.6)

	elseif mode == "RIPPLE" then
		local p = (t * 0.5 + (k % 3) / 3) % 1
		local ang = math.floor(k / 3) * TAU / math.ceil(N / 3)
		return Vector3.new(math.cos(ang) * p * R * 1.8, -2.2 + H * 0.25 + 0.4, math.sin(ang) * p * R * 1.8)

	elseif mode == "METEORS" then
		local p = (t * 0.45 + k / N) % 1
		local a = k * 2.4
		local sx, sz = math.cos(a) * R * 1.4, math.sin(a) * R * 1.4
		return Vector3.new(sx, H + R * 2.2, sz):Lerp(Vector3.new(sx * 0.2 - 3, H - 1, sz * 0.2), p)

	elseif mode == "STAR8" then
		local a = k / N * TAU + t * W * 0.4
		local r = (k % 2 == 0) and R or R * 0.45
		return Vector3.new(math.cos(a) * r, H + R * 0.8 + 3 + math.sin(a) * r, -R * 1.1)

	elseif mode == "SATURN" then
		local c = Vector3.new(0, H + R * 0.7 + 3, 0)
		if k == 0 then return c + Vector3.new(0, math.sin(t * 2) * 0.4, 0) end
		local a = (k - 1) / math.max(N - 1, 1) * TAU + t * W * 0.7
		return c + CFrame.Angles(0, 0, 0.45):VectorToWorldSpace(Vector3.new(math.cos(a) * R * 0.9, 0, math.sin(a) * R * 0.9))

	elseif mode == "ROSE" then
		local a = t * W * 0.5 + k * 0.7
		local r = math.cos(4 * a) * R
		return Vector3.new(math.cos(a) * r, H + R * 0.8 + 3 + math.sin(a) * r, -R * 1.1)

	elseif mode == "BUTTERFLY" then
		local a = t * W * 0.6 + k * 0.9
		local r = math.exp(math.sin(a)) - 2 * math.cos(4 * a) + math.sin((2 * a - math.pi) / 24) ^ 5
		return Vector3.new(math.sin(a) * r * R * 0.3, H + R * 0.8 + 3 + math.cos(a) * r * R * 0.3, -R * 1.1)

	elseif mode == "BOUNCE" then
		local a = k / N * TAU + t * 0.5
		return Vector3.new(math.cos(a) * R * 0.9, -1.8 + H * 0.25 + math.abs(math.sin(t * 3 + k * 0.8)) * R * 0.8, math.sin(a) * R * 0.9)

	elseif mode == "PILLAR" then
		local a = t * 4 + k * 2.4
		local tri = 1 - math.abs(((t * 0.7 + k / N) % 1) * 2 - 1)
		return Vector3.new(math.cos(a) * 1.6, H - 2 + tri * R * 2, math.sin(a) * 1.6)

	elseif mode == "WEB" then
		local a = k / N * TAU * 2.5 + t * W * 0.5
		local r = R * (0.15 + 0.85 * (k / math.max(N - 1, 1)))
		return Vector3.new(math.cos(a) * r, H + R * 0.8 + 3 + math.sin(a) * r, -R)

	elseif mode == "JELLY" then
		local a = k / N * TAU + t * 0.4
		local pulse, top = 0.8 + 0.2 * math.sin(t * 2.5), H + R * 0.9 + 2
		if k % 2 == 0 then return Vector3.new(math.cos(a) * R * 0.8 * pulse, top, math.sin(a) * R * 0.8 * pulse) end
		return Vector3.new(math.cos(a) * R * 0.5, top - R * 0.5 - 1.5 - math.sin(t * 3 + k) * 1.2, math.sin(a) * R * 0.5)

	elseif mode == "TURBINE" then
		local j = (math.floor(k / 3) + 1) / math.ceil(N / 3)
		local a = (k % 3) * TAU / 3 + t * W * 1.4
		local r = R * (0.2 + 0.8 * j)
		return Vector3.new(math.cos(a) * r, H + R * 0.9 + 3 + math.sin(a) * r, -R)

	elseif mode == "COASTER" then
		local a = k / N * TAU + t * W * 0.8
		return Vector3.new(math.cos(a) * R, H + 3 + R * 0.5 * (1 - math.cos(3 * a)), math.sin(a) * R)

	elseif mode == "SCANNER" then
		return Vector3.new(math.sin(t * W * 1.3) * R * 1.4, H + 1 + k / math.max(N - 1, 1) * R * 1.2, -R * 0.9)

	elseif mode == "NEWTON" then
		local x, len, ang = (k - (N - 1) / 2) * 1.6, R * 0.9, 0
		local s = math.sin(t * W * 1.6)
		if (k == 0 and s > 0) or (k == N - 1 and s < 0) then ang = -s * 0.9 end
		return Vector3.new(x + math.sin(ang) * len, H + R * 0.9 + 4 - math.cos(ang) * len, -R * 0.7)

	elseif mode == "LIGHTHOUSE" then
		local a = t * W * 0.8 + ((k % 2 == 0) and 0 or math.pi)
		local r = R * (0.3 + math.floor(k / 2) / math.max(math.ceil(N / 2), 1) * 1.2)
		return Vector3.new(math.cos(a) * r, H + 3, math.sin(a) * r)

	elseif mode == "FOUNTAIN" then
		local p = (t * 0.6 + k / N) % 1
		local ang = k * 2.4
		return Vector3.new(math.cos(ang) * R * 0.9 * p, H - 2 + 4 * p * (1 - p) * R * 1.2, math.sin(ang) * R * 0.9 * p)

	elseif mode == "LIGHTNING" then
		return Vector3.new(math.noise(t * 6, k * 1.7, 0) * R * 0.8, H + R * 2 - k / math.max(N - 1, 1) * R * 2, -R * 1.1)
	end
	return Vector3.new(0, H, 0)
end

local bhCore = make("Part", {Name = "FembiixBH", Shape = Enum.PartType.Ball, Size = Vector3.new(2.4, 2.4, 2.4),
	Color = Color3.new(0, 0, 0), Material = Enum.Material.SmoothPlastic, Anchored = true, CanCollide = false,
	CanQuery = false, CanTouch = false, CastShadow = false})
local bhGlow = make("Part", {Name = "FembiixBHGlow", Shape = Enum.PartType.Ball, Size = Vector3.new(3.6, 3.6, 3.6),
	Color = C.accent, Material = Enum.Material.Neon, Transparency = 0.7, Anchored = true, CanCollide = false,
	CanQuery = false, CanTouch = false, CastShadow = false})
local function bhHide() bhCore.Parent = nil; bhGlow.Parent = nil end

local function makeEmitter(part)
	return make("ParticleEmitter", {
		Rate = 60, Lifetime = NumberRange.new(0.35, 0.9), Speed = NumberRange.new(4, 12),
		SpreadAngle = Vector2.new(180, 180), LightEmission = 1, Acceleration = Vector3.new(0, -14, 0),
		Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.45), NumberSequenceKeypoint.new(1, 0)}),
		Color = ColorSequence.new(SPARK_C1, SPARK_C2),
		Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1)}),
		Rotation = NumberRange.new(0, 360), RotSpeed = NumberRange.new(-200, 200),
	}, part)
end

local function refreshFx(s)
	local part = s.part
	if sparkFx and not s.pe then
		s.pe = makeEmitter(part)
		s.rb = nil
	elseif not sparkFx and s.pe then
		s.pe:Destroy(); s.pe = nil
	end
	if sparkFx and not s.pl then
		s.pl = make("PointLight", {Range = 12, Brightness = 1.6, Color = SPARK_C1, Shadows = false}, part)
		s.rb = nil
	elseif not sparkFx and s.pl then
		s.pl:Destroy(); s.pl = nil
	end
	if sparkTrail and not s.tr then
		s.a0 = make("Attachment", {Name = "FembiixT0", Position = Vector3.new(0, 0.4, 0)}, part)
		s.a1 = make("Attachment", {Name = "FembiixT1", Position = Vector3.new(0, -0.4, 0)}, part)
		s.tr = make("Trail", {
			Attachment0 = s.a0, Attachment1 = s.a1, Lifetime = 0.7, MinLength = 0.05, LightEmission = 1, FaceCamera = true,
			Transparency = NumberSequence.new(0.1, 1), Color = ColorSequence.new(SPARK_C1, SPARK_C2),
		}, part)
		s.rb = nil
	s.textFx = nil
	elseif not sparkTrail and s.tr then
		s.tr:Destroy(); s.a0:Destroy(); s.a1:Destroy()
		s.tr, s.a0, s.a1 = nil, nil, nil
	end
end

local function paintSparkler(s, c1, c2)
	if s.pe then s.pe.Color = ColorSequence.new(c1, c2) end
	if s.tr then s.tr.Color = ColorSequence.new(c1, c2) end
	if s.pl then s.pl.Color = c1 end
end

local function addSparkler(obj, part)
	local s = {obj = obj, part = part, collide = {}, m0 = os.clock(), prev = part.Position}
	local list = {}
	if obj:IsA("BasePart") then list[#list + 1] = obj end
	for _, d in ipairs(obj:GetDescendants()) do
		if d:IsA("BasePart") then list[#list + 1] = d end
	end
	for _, p in ipairs(list) do
		s.collide[p] = p.CanCollide
		p.CanCollide = false
	end
	s.att = make("Attachment", {Name = "FembiixAtt"}, part)
	s.ap = make("AlignPosition", {
		Mode = Enum.PositionAlignmentMode.OneAttachment, Attachment0 = s.att, RigidityEnabled = false,
		MaxForce = math.huge, Responsiveness = ui.spResp.Get(), ApplyAtCenterOfMass = true, Position = part.Position,
	}, part)
	s.ao = make("AlignOrientation", {
		Mode = Enum.OrientationAlignmentMode.OneAttachment, Attachment0 = s.att,
		MaxTorque = math.huge, Responsiveness = 30, CFrame = part.CFrame,
	}, part)
	refreshFx(s)
	if s.pe then s.pe:Emit(40) end -- вспышка при захвате
	sparklers[#sparklers + 1] = s
	sparklerSet[obj] = true
end

local function releaseSparklerAt(idx)
	local s = table.remove(sparklers, idx)
	if not s then return end
	sparklerSet[s.obj] = nil
	for _, o in ipairs({s.ap, s.ao, s.att, s.pe, s.tr, s.a0, s.a1, s.pl}) do
		pcall(function() o:Destroy() end)
	end
	for p, c in pairs(s.collide) do
		if p.Parent then p.CanCollide = c end
	end
end
local function releaseAllSparklers()
	for i = #sparklers, 1, -1 do releaseSparklerAt(i) end
	tail = {}
	bhHide()
	wireClear()
end
local function applyFx()
	for _, s in ipairs(sparklers) do refreshFx(s) end
end

local function captureNearby()
	local hrp, folder = getHRP(), getFolder()
	if not hrp or not folder then return 0 end
	local max, added = ui.spCount.Get(), 0
	for _, child in ipairs(folder:GetChildren()) do
		if #sparklers >= max then break end
		if child.Name == "FireworkSparkler" and not sparklerSet[child] then
			local part = resolvePart(child)
			if part and (part.Position - hrp.Position).Magnitude <= captureRange then
				addSparkler(child, part)
				added += 1
			end
		end
	end
	if added > 0 then notify("🎆 Захвачено спаркеров: +" .. added) end
	return added
end

-- ===== надпись: рисуем слово бенгальскими огнями (штриховой шрифт) =====
-- глифы: список штрихов, штрих = список точек {x, y}; сетка 2 x 4
TXT.G = {
	A = {{{0,0},{1,4},{2,0}}, {{0.5,1.6},{1.5,1.6}}},
	B = {{{0,0},{0,4},{1.4,4},{2,3.2},{1.4,2.2},{0,2.2},{1.5,2.2},{2,1},{1.4,0},{0,0}}},
	C = {{{2,3.4},{1.5,4},{0.5,4},{0,3.3},{0,0.7},{0.5,0},{1.5,0},{2,0.6}}},
	D = {{{0,0},{0,4},{1.2,4},{2,3},{2,1},{1.2,0},{0,0}}},
	E = {{{2,4},{0,4},{0,2},{1.5,2},{0,2},{0,0},{2,0}}},
	F = {{{2,4},{0,4},{0,2},{1.5,2},{0,2},{0,0}}},
	G = {{{2,3.4},{1.5,4},{0.5,4},{0,3.3},{0,0.7},{0.5,0},{1.5,0},{2,0.7},{2,2},{1,2}}},
	H = {{{0,0},{0,4},{0,2},{2,2},{2,4},{2,0}}},
	I = {{{0.3,4},{1.7,4},{1,4},{1,0},{0.3,0},{1.7,0}}},
	J = {{{0,1},{0.5,0},{1.5,0},{2,0.7},{2,4}}},
	K = {{{0,0},{0,4},{0,2},{2,4},{0,2},{2,0}}},
	L = {{{0,4},{0,0},{2,0}}},
	M = {{{0,0},{0,4},{1,2},{2,4},{2,0}}},
	N = {{{0,0},{0,4},{2,0},{2,4}}},
	O = {{{0.5,0},{0,0.7},{0,3.3},{0.5,4},{1.5,4},{2,3.3},{2,0.7},{1.5,0},{0.5,0}}},
	P = {{{0,0},{0,4},{1.5,4},{2,3.3},{2,2.7},{1.5,2},{0,2}}},
	Q = {{{0.5,0},{0,0.7},{0,3.3},{0.5,4},{1.5,4},{2,3.3},{2,0.7},{1.5,0},{0.5,0}}, {{1.1,1.1},{2,-0.3}}},
	R = {{{0,0},{0,4},{1.5,4},{2,3.3},{2,2.7},{1.5,2},{0,2},{1,2},{2,0}}},
	S = {{{2,3.4},{1.5,4},{0.5,4},{0,3.3},{0,2.7},{0.5,2},{1.5,2},{2,1.3},{2,0.7},{1.5,0},{0.5,0},{0,0.6}}},
	T = {{{0,4},{2,4},{1,4},{1,0}}},
	U = {{{0,4},{0,0.7},{0.5,0},{1.5,0},{2,0.7},{2,4}}},
	V = {{{0,4},{1,0},{2,4}}},
	W = {{{0,4},{0.5,0},{1,2},{1.5,0},{2,4}}},
	X = {{{0,4},{2,0},{1,2},{0,0},{2,4}}},
	Y = {{{0,4},{1,2},{2,4},{1,2},{1,0}}},
	Z = {{{0,4},{2,4},{0,0},{2,0}}},
}
TXT.G["0"] = TXT.G.O
TXT.G["1"] = {{{0.4,3},{1,4},{1,0}}}
TXT.G["2"] = {{{0,3.3},{0.5,4},{1.5,4},{2,3.3},{2,2.7},{0,0},{2,0}}}
TXT.G["3"] = {{{0,3.5},{0.5,4},{1.5,4},{2,3.3},{1.5,2.2},{0.8,2.2},{1.5,2.2},{2,1.5},{1.5,0},{0.5,0},{0,0.5}}}
TXT.G["4"] = {{{1.5,0},{1.5,4},{0,1.2},{2,1.2}}}
TXT.G["5"] = {{{2,4},{0,4},{0,2.2},{1.5,2.4},{2,1.7},{2,0.7},{1.5,0},{0.5,0},{0,0.5}}}
TXT.G["6"] = {{{1.8,4},{0.5,3.5},{0,2},{0,0.7},{0.5,0},{1.5,0},{2,0.7},{2,1.5},{1.5,2.2},{0.5,2.2},{0,1.7}}}
TXT.G["7"] = {{{0,4},{2,4},{0.7,0}}}
TXT.G["8"] = {{{0.5,2},{0,2.7},{0,3.3},{0.5,4},{1.5,4},{2,3.3},{2,2.7},{1.5,2},{0.5,2},{0,1.3},{0,0.7},{0.5,0},{1.5,0},{2,0.7},{2,1.3},{1.5,2}}}
TXT.G["9"] = {{{0.2,0},{1.5,0.5},{2,2},{2,3.3},{1.5,4},{0.5,4},{0,3.3},{0,2.5},{0.5,1.8},{1.5,1.8},{2,2.3}}}
-- кириллица: похожие на латиницу буквы + свои глифы (коды, чтобы не перепутать раскладку)
TXT.CYR = {}
for cyr, lat in pairs({[0x410] = "A", [0x412] = "B", [0x415] = "E", [0x41A] = "K", [0x41C] = "M", [0x41D] = "H",
	[0x41E] = "O", [0x420] = "P", [0x421] = "C", [0x422] = "T", [0x423] = "Y", [0x425] = "X"}) do
	TXT.CYR[utf8.char(cyr)] = lat
end
TXT.G[utf8.char(0x411)] = {{{2,4},{0,4},{0,0},{1.4,0},{2,0.9},{1.4,2.1},{0,2.1}}} -- Б
TXT.G[utf8.char(0x413)] = {{{0,0},{0,4},{2,4}}} -- Г
TXT.G[utf8.char(0x418)] = {{{0,4},{0,0},{2,4},{2,0}}} -- И
TXT.G[utf8.char(0x41B)] = {{{0,0},{0.6,4},{2,4},{2,0}}} -- Л
TXT.G[utf8.char(0x41F)] = {{{0,0},{0,4},{2,4},{2,0}}} -- П
TXT.G[utf8.char(0x424)] = {{{1,0},{1,4}}, {{1,3.1},{0.3,2.9},{0,2},{0.3,1.1},{1,0.9},{1.7,1.1},{2,2},{1.7,2.9},{1,3.1}}} -- Ф

function TXT.build(text)
	local chars = {}
	for _, cp in utf8.codes(text) do
		if cp >= 0x430 and cp <= 0x44F then cp -= 32 end
		local ch = utf8.char(cp):upper()
		chars[#chars + 1] = TXT.CYR[ch] or ch
		if #chars >= 14 then break end
	end
	local n = #chars
	local gap = 1.1
	local totalW = n * 2 + math.max(n - 1, 0) * gap
	local segs, C0 = {}, 0
	local pen, first
	local function add(a, b, down)
		local len = (b - a).Magnitude
		if len < 1e-4 then return end
		local cost = down and len or len * 0.4 -- пустой перелёт быстрее
		segs[#segs + 1] = {a = a, b = b, down = down, cost = cost, cum = C0}
		C0 += cost
	end
	for ci, ch in ipairs(chars) do
		local g = TXT.G[ch]
		if g then
			local ox = (ci - 1) * (2 + gap) - totalW / 2
			for _, stroke in ipairs(g) do
				local p0 = Vector2.new(ox + stroke[1][1], stroke[1][2] - 2)
				if pen then add(pen, p0, false) else first = p0 end
				pen = p0
				for k = 2, #stroke do
					local p = Vector2.new(ox + stroke[k][1], stroke[k][2] - 2)
					add(pen, p, true)
					pen = p
				end
			end
		end
	end
	if pen and first then add(pen, first, false) end
	return {segs = segs, cost = C0, totalW = totalW}
end

function TXT.penAt(path, s)
	local segs = path.segs
	local lo, hi = 1, #segs
	while lo < hi do
		local mid = math.floor((lo + hi + 1) / 2)
		if segs[mid].cum <= s then lo = mid else hi = mid - 1 end
	end
	local sg = segs[lo]
	local f = math.clamp((s - sg.cum) / sg.cost, 0, 1)
	return sg.a:Lerp(sg.b, f), sg.down
end

function TXT.get()
	if TXT.key ~= TXT.text then
		TXT.path = TXT.build(TXT.text)
		TXT.key = TXT.text
	end
	return TXT.path
end

-- настройка шлейфа под режим надписи (тонкий и долгий, чтобы слово было видно целиком)
function TXT.fx(s, on, life)
	if on then
		if s.tr and (s.textFx ~= true or math.abs((s.trLife or 0) - life) > 0.05) then
			s.tr.Lifetime = life
			s.trLife = life
			if s.textFx ~= true then
				s.tr.Transparency = NumberSequence.new(0, 0.85)
				if s.a0 then s.a0.Position = Vector3.new(0, 0.22, 0) end
				if s.a1 then s.a1.Position = Vector3.new(0, -0.22, 0) end
			end
		end
		s.textFx = true
	elseif s.textFx then
		s.textFx = nil
		s.ap.Enabled = true
		if s.tr then
			s.tr.Enabled = true
			s.tr.Lifetime = 0.7
			s.tr.Transparency = NumberSequence.new(0.1, 1)
		end
		if s.a0 then s.a0.Position = Vector3.new(0, 0.4, 0) end
		if s.a1 then s.a1.Position = Vector3.new(0, -0.4, 0) end
		if s.pe then s.pe.Enabled = true end
	end
end

local function updateSparklers(dt, now)
	wire.used = 0
	local hrp = getHRP()
	if not hrp then wireEnd(); bhHide(); return end

	for i = #sparklers, 1, -1 do
		local s = sparklers[i]
		if not s.part.Parent or not s.part:IsDescendantOf(workspace) then releaseSparklerAt(i) end
	end
	local maxN = ui.spCount.Get()
	while #sparklers > maxN do releaseSparklerAt(#sparklers) end

	captureTimer -= dt
	if autoCapture and captureTimer <= 0 and #sparklers < maxN then
		captureTimer = 0.5
		captureNearby()
	end

	local N = #sparklers
	if ui.spStatus then
		local txt = ("Захвачено: %d / %d"):format(N, maxN)
		if ui.spStatus.Text ~= txt then ui.spStatus.Text = txt end
	end
	if N == 0 then bhHide(); wireEnd(); return end

	if sparkMorph then -- смена режима: плавный перелёт в новую фигуру
		sparkMorph = false
		for _, s in ipairs(sparklers) do
			s.prev = s.part.Position
			s.m0 = now
		end
	end

	local R0, H, W, resp = ui.spRadius.Get(), ui.spHeight.Get(), ui.spSpin.Get(), ui.spResp.Get()
	local R = R0 * (1 + 0.05 * math.sin(now * 3)) -- «дыхание» фигуры
	local flat = flatten(hrp.CFrame.LookVector)
	baseLook = safeUnit(baseLook:Lerp(flat, math.clamp(dt * 10, 0, 1)), flat)
	local base = CFrame.lookAt(hrp.Position, hrp.Position + baseLook)
	local mode = sparkModeKey
	local jitter = (mode == "CUBE" or mode == "PENTAGRAM" or mode == "NAME" or mode == "PYRAMID" or mode == "CROWN" or mode == "STAR8" or mode == "NEWTON" or mode == "LIGHTNING" or mode == "LIGHTHOUSE" or mode == "SCANNER") and 0 or 0.4

	-- режим «Надпись»: огни — это перья, они очень быстро обводят буквы
	local textMode, path, unit, vGrid, dist, cy, trailLife = false, nil, 1, 1, 14, 0, 1
	if mode == "NAME" then
		path = TXT.get()
		if path and #path.segs > 0 and path.cost > 0 then
			textMode = true
			local hGlyph = math.max(R0, 2) * 0.6
			unit = hGlyph / 4
			vGrid = (14 + W * 9) / unit
			dist = math.max(14, path.totalW * unit * 0.8)
			cy = H + hGlyph * 0.5 + 3
			trailLife = math.clamp(path.cost / (N * vGrid) * 1.1 + 0.15, 0.3, 4)
		end
	end

	local chain
	if mode == "TAIL" then
		local back = -baseLook
		local spacing = math.max(1.5, R * 0.35)
		chain = tail
		chain[1] = hrp.Position + Vector3.new(0, H * 0.3, 0) + back * 2.2
		for i = 2, N do
			local prev = chain[i - 1]
			local cur = chain[i] or (prev + back * spacing)
			local d = cur - prev
			if d.Magnitude < 0.01 then d = back end
			chain[i] = prev + d.Unit * spacing
		end
	end
	local right = baseLook:Cross(Vector3.yAxis)

	for i, s in ipairs(sparklers) do
		local target, penDown
		if textMode then
			local sp = (now * vGrid + (i - 1) * path.cost / N) % path.cost
			local p2, down = TXT.penAt(path, sp)
			target = base:PointToWorldSpace(Vector3.new(p2.X * unit, cy + p2.Y * unit, -dist))
			penDown = down
		elseif chain then
			target = chain[i] + right * (math.sin(now * W * 2 - i * 0.7) * 0.8)
		else
			local dp = (mode == "DRAGON" and API.dragonSparkPos) and API.dragonSparkPos(i, N, now) or nil
			if dp then
				target = dp
			else
				target = base:PointToWorldSpace(sparkOffset((mode == "DRAGON") and "COMET" or mode, i, N, now, R, H, W))
			end
		end
		if jitter > 0 then
			target += Vector3.new(math.noise(now * 1.3, i * 7.1, 0), math.noise(now * 1.1, i * 3.3, 5), math.noise(now * 1.2, i * 5.5, 9)) * jitter
		end
		local m = easeOutCubic((now - s.m0) / 0.9)
		if m < 1 then
			target = s.prev:Lerp(target, m)
			penDown = false
		end

		if textMode then
			TXT.fx(s, true, trailLife)
			s.ap.Enabled = false -- перо двигаем напрямую, без задержки физики
			moveObj(s.obj, s.part, CFrame.new(target))
			s.part.AssemblyLinearVelocity = Vector3.zero
			s.part.AssemblyAngularVelocity = Vector3.zero
			if s.tr then s.tr.Enabled = penDown and true or false end
			if s.pe then s.pe.Enabled = penDown and true or false end
		else
			TXT.fx(s, false)
			s.ap.Position = target
			s.ap.Responsiveness = resp
		end
		s.ao.CFrame = CFrame.Angles(0, now * 2 + i, 0)

		-- эффекты: чем быстрее огонь, тем гуще искры; свет мерцает
		local vel = textMode and 90 or s.part.AssemblyLinearVelocity.Magnitude
		if s.pe then s.pe.Rate = math.clamp(55 + vel * 3.5, 55, 240) end
		if s.pl then s.pl.Brightness = 1.1 + math.random() * 1.4 end
		if sparkRainbow then
			local h = (now * 0.12 + i / N) % 1
			paintSparkler(s, Color3.fromHSV(h, 0.65, 1), Color3.fromHSV((h + 0.1) % 1, 1, 1))
			s.rb = true
		elseif s.rb ~= false then
			paintSparkler(s, SPARK_C1, SPARK_C2)
			s.rb = false
		end
	end

	-- каркасы
	if mode == "CUBE" then
		local rot = cubeBasis(now, W)
		local col = wireColor(now)
		local corners = {}
		for ci = 0, 7 do corners[ci] = base:PointToWorldSpace(cubeCorner(ci, rot, R, H)) end
		local th = 0.14 + 0.04 * math.sin(now * 9)
		for ci = 0, 7 do
			for _, bit in ipairs({1, 2, 4}) do
				local cj = bit32.bxor(ci, bit)
				if cj > ci then wireLine(corners[ci], corners[cj], col, th, true) end
			end
		end
	elseif mode == "PENTAGRAM" then
		local col = wireColor(now)
		for j = 0, 4 do
			wireLine(base:PointToWorldSpace(starVertex(j, now, R, H)), base:PointToWorldSpace(starVertex(j + 1, now, R, H)), col, 0.13, true)
		end
		local y = -2.2 + H * 0.25
		for j = 0, 19 do
			local a1, a2 = j / 20 * TAU + now * 0.4, (j + 1) / 20 * TAU + now * 0.4
			wireLine(
				base:PointToWorldSpace(Vector3.new(math.sin(a1) * R, y, -math.cos(a1) * R)),
				base:PointToWorldSpace(Vector3.new(math.sin(a2) * R, y, -math.cos(a2) * R)),
				col, 0.09, false)
		end
	end
	if mode == "PYRAMID" then
		local col = wireColor(now)
		local apex = base:PointToWorldSpace(TXT.pyrVert(0, now, R, H, W))
		local bs = {}
		for i = 1, 4 do bs[i] = base:PointToWorldSpace(TXT.pyrVert(i, now, R, H, W)) end
		for i = 1, 4 do
			wireLine(apex, bs[i], col, 0.13, true)
			wireLine(bs[i], bs[i % 4 + 1], col, 0.13, true)
		end
	elseif mode == "STAR8" then
		local col = wireColor(now)
		for i = 1, N do
			wireLine(base:PointToWorldSpace(sparkOffset("STAR8", i, N, now, R, H, W)), base:PointToWorldSpace(sparkOffset("STAR8", i % N + 1, N, now, R, H, W)), col, 0.1, true)
		end
	elseif mode == "LIGHTHOUSE" then
		local col = wireColor(now)
		local c = base:PointToWorldSpace(Vector3.new(0, H + 3, 0))
		for i = 1, N do wireLine(c, base:PointToWorldSpace(sparkOffset("LIGHTHOUSE", i, N, now, R, H, W)), col, 0.12, true) end
	elseif mode == "LIGHTNING" then
		local col = Color3.fromHSV(0.62, 0.35, 1)
		for i = 1, N - 1 do
			wireLine(base:PointToWorldSpace(sparkOffset("LIGHTNING", i, N, now, R, H, W)), base:PointToWorldSpace(sparkOffset("LIGHTNING", i + 1, N, now, R, H, W)), col, 0.14, true)
		end
	elseif mode == "NEWTON" then
		for i = 1, N do
			local x = (i - 1 - (N - 1) / 2) * 1.6
			wireLine(base:PointToWorldSpace(Vector3.new(x, H + R * 0.9 + 4, -R * 0.7)), base:PointToWorldSpace(sparkOffset("NEWTON", i, N, now, R, H, W)), Color3.fromRGB(200, 205, 225), 0.06, false)
		end
	elseif mode == "DRAGON" then -- языки пламени из пасти при дыхании
		local di = API.dragonInfo and API.dragonInfo()
		if di and di.breath > 0 then
			for k = 1, 10 do
				local w = now * 9 + k * 2.3
				local rnd = Vector3.new(math.noise(w, 0.3, 0), math.noise(w, 4.1, 0), math.noise(w, 8.9, 0))
				local tip = di.head + di.fwd * (6 + 14 * di.breath * (0.5 + math.random() * 0.5)) + rnd * 6 * di.breath
				wireLine(di.head + di.fwd * 1.5, tip, Color3.fromHSV(0.02 + math.random() * 0.1, 1, 1), 0.2 + math.random() * 0.25, true)
			end
		end
	elseif mode == "CROWN" then
		local col = wireColor(now)
		for i = 1, N do
			local a = base:PointToWorldSpace(sparkOffset("CROWN", i, N, now, R, H, W))
			local b = base:PointToWorldSpace(sparkOffset("CROWN", i % N + 1, N, now, R, H, W))
			wireLine(a, b, col, 0.1, true)
		end
	end
	wireEnd()

	if mode == "BLACKHOLE" then
		local c = base:PointToWorldSpace(Vector3.new(0, H + 2, -(R * 1.2 + 2)))
		local pulse = 1 + 0.08 * math.sin(now * 5)
		bhCore.Size = Vector3.new(2.4, 2.4, 2.4) * pulse
		bhGlow.Size = Vector3.new(3.6, 3.6, 3.6) * pulse
		bhCore.CFrame = CFrame.new(c)
		bhGlow.CFrame = CFrame.new(c)
		bhCore.Parent = camera
		bhGlow.Parent = camera
	else
		bhHide()
	end
end

-- ============================ ИНТЕРФЕЙС ============================
local isTouch = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

local screenGui = make("ScreenGui", {Name = "FembiixGui", IgnoreGuiInset = true, DisplayOrder = 50,
	ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling})
pcall(function() screenGui.Parent = CoreGui end)
if not screenGui.Parent then screenGui.Parent = player:WaitForChild("PlayerGui") end

-- прицел (старый) и новый прицел толпы
ui.cross = make("Frame", {Size = UDim2.new(0, 8, 0, 8), Position = UDim2.new(0.5, -4, 0.5, 111),
	BackgroundColor3 = Color3.fromRGB(255, 40, 20), BorderSizePixel = 0}, screenGui)
round(ui.cross, 4)

ui.aim = make("Frame", {Size = UDim2.new(0, 34, 0, 34), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0),
	BackgroundTransparency = 1, Visible = false}, screenGui)
round(ui.aim, 20)
ui.aimStroke = stroke(ui.aim, Color3.fromRGB(255, 60, 30), 2, 0.1)
do
	local dot = make("Frame", {Size = UDim2.new(0, 4, 0, 4), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0),
		BackgroundColor3 = C.accent, BorderSizePixel = 0}, ui.aim)
	round(dot, 2)
end

-- подсказка запуска
ui.hint = make("TextLabel", {Size = UDim2.new(0, 340, 0, 34), Position = UDim2.new(0.5, -170, 0, 50),
	BackgroundColor3 = C.bg, BackgroundTransparency = 0.15, TextColor3 = C.accent, Font = Enum.Font.GothamBold,
	TextSize = 14, Text = "🎃 Кликни по ракете, чтобы запустить", Visible = false}, screenGui)
round(ui.hint, 10)
stroke(ui.hint, C.accent, 1.5, 0.2)

-- всплывающие уведомления
local toastHolder = make("Frame", {Name = "Toasts", Size = UDim2.new(0, 400, 0, 220), AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, -24), BackgroundTransparency = 1}, screenGui)
make("UIListLayout", {VerticalAlignment = Enum.VerticalAlignment.Bottom, HorizontalAlignment = Enum.HorizontalAlignment.Center,
	Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder}, toastHolder)
notify = function(text, color)
	local t = make("TextLabel", {Size = UDim2.new(1, 0, 0, 34), BackgroundColor3 = C.panel, BackgroundTransparency = 1, Text = text,
		TextColor3 = C.text, Font = Enum.Font.GothamBold, TextSize = 13, TextTransparency = 1, BorderSizePixel = 0,
		TextWrapped = true}, toastHolder)
	round(t, 8)
	local st = stroke(t, color or C.accent, 1.5, 1)
	tween(t, {BackgroundTransparency = 0.08, TextTransparency = 0}, 0.2)
	tween(st, {Transparency = 0.2}, 0.2)
	task.delay(2.6, function()
		if not t.Parent then return end
		tween(t, {BackgroundTransparency = 1, TextTransparency = 1}, 0.3)
		tween(st, {Transparency = 1}, 0.3)
		task.delay(0.35, function() t:Destroy() end)
	end)
end

-- кнопка запуска толпы (для телефона и вообще)
ui.fireBtn = make("TextButton", {Size = UDim2.new(0, 84, 0, 84), AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -24, 1, -110),
	BackgroundColor3 = C.accentDark, Text = "🚀", TextSize = 36, AutoButtonColor = false, Visible = false, BorderSizePixel = 0}, screenGui)
round(ui.fireBtn, 42)
stroke(ui.fireBtn, C.accent, 3, 0.1)
ui.fireBtn.Activated:Connect(function() API.petAction() end)

-- ======================= ПОДСКАЗКИ ПРИ НАВЕДЕНИИ =======================
do
	if DEVICE ~= "ПК" then
		function UIK.tip() end
	else
		local tf = make("TextLabel", {Size = UDim2.fromOffset(250, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = Color3.fromRGB(28, 32, 54),
			TextColor3 = Color3.new(1, 1, 1), Font = Enum.Font.GothamMedium, TextSize = 12, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left,
			BorderSizePixel = 0, Visible = false, ZIndex = 200}, screenGui)
		round(tf, 8)
		make("UIPadding", {PaddingTop = UDim.new(0, 7), PaddingBottom = UDim.new(0, 7), PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10)}, tf)
		local cur, since, curText = nil, 0, ""
		function UIK.tip(obj, text)
			obj.MouseEnter:Connect(function() cur, since, curText = obj, os.clock(), text end)
			obj.MouseLeave:Connect(function()
				if cur == obj then cur = nil; tf.Visible = false end
			end)
		end
		connect(RunService.RenderStepped, function()
			if cur and os.clock() - since > 0.35 and cur.Parent then
				local m, vs = UserInputService:GetMouseLocation(), camera.ViewportSize
				tf.Text = curText
				tf.Position = UDim2.fromOffset(math.min(m.X + 16, vs.X - 262), math.min(m.Y + 18, vs.Y - 90))
				tf.Visible = true
			elseif tf.Visible and not cur then
				tf.Visible = false
			end
		end)
	end
end

-- ======================= ОКНО: АДМИН-ПАНЕЛЬ, БЕЛАЯ ТЕМА =======================
local userMul = API.cfg.userMul or 1
local function autoScale() -- окно всегда помещается в экран: ПК / планшет / телефон
	local vp = camera.ViewportSize
	return math.clamp(math.min((vp.X - 24) / UIK.W, (vp.Y - 24) / UIK.H), 0.45, 1.15)
end
local userScale = autoScale() * userMul
local MainFrame = make("Frame", {Name = "Main", Size = UDim2.fromOffset(UIK.W, UIK.H), AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.new(0.5, 0, 0.5, 0), BackgroundTransparency = 1, Active = true}, screenGui)
local uiScale = make("UIScale", {Scale = userScale}, MainFrame)
connect(camera:GetPropertyChangedSignal("ViewportSize"), function()
	userScale = autoScale() * userMul
	uiScale.Scale = userScale
end)
MainFrame.MouseEnter:Connect(function() overMain = true end)
MainFrame.MouseLeave:Connect(function() overMain = false end)

local bubble, hidden, setHidden
local pagesHolder, selectTab
local pages, tabBtns, currentTab = {}, {}, nil
local TABS = {
	{"rockets", "🕹", "Ручная ракета"}, {"swarm", "🐕", "Моя ракета"}, {"sparklers", "🎆", "Спаркеры"},
	{"world", "🌍", "Мир и камера"}, {"players", "👥", "Игроки"}, {"settings", "⚙", "Настройки"},
}

do
	-- мягкая многослойная тень
	UIK.shadows = {}
	for i = 1, 4 do
		local s = make("Frame", {Size = UDim2.new(1, i * 12, 1, i * 12), Position = UDim2.new(0, -i * 6, 0, -i * 6 + 10),
			BackgroundColor3 = Color3.fromRGB(50, 60, 110), BackgroundTransparency = 0.955, BorderSizePixel = 0}, MainFrame)
		round(s, 18 + i * 8)
		UIK.shadows[i] = s
	end
	local Win = make("Frame", {Name = "Win", Size = UDim2.fromScale(1, 1), BackgroundColor3 = C.bg, BorderSizePixel = 0, ClipsDescendants = true}, MainFrame)
	round(Win, 18)
	make("UIGradient", {Color = ColorSequence.new(Color3.fromRGB(253, 254, 255), Color3.fromRGB(233, 238, 253)), Rotation = 90}, Win)
	stroke(Win, Color3.fromRGB(208, 215, 240), 1.5, 0)

	-- плывущие пастельные пятна (без нагрузки: просто твины)
	for i, o in ipairs({{0.15, 0.2, Color3.fromRGB(170, 185, 255)}, {0.92, 0.88, Color3.fromRGB(255, 190, 225)}, {0.88, 0.1, Color3.fromRGB(170, 235, 255)}}) do
		local f = make("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(o[1], o[2]), Size = UDim2.fromOffset(320, 320),
			BackgroundColor3 = o[3], BackgroundTransparency = 0.78, BorderSizePixel = 0}, Win)
		round(f, 320)
		tween(f, {Position = UDim2.fromScale(o[1] + ((i % 2 == 0) and 0.08 or -0.08), o[2] - 0.06), BackgroundTransparency = 0.88}, 4 + i, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
	end

	-- шапка
	local Head = make("Frame", {Size = UDim2.new(1, 0, 0, 56), BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0.25, BorderSizePixel = 0, Active = true}, Win)
	local logo = make("Frame", {Size = UDim2.fromOffset(36, 36), Position = UDim2.new(0, 14, 0, 10), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0}, Head)
	round(logo, 11)
	local lg = make("UIGradient", {Color = ColorSequence.new(C.accent, Color3.fromRGB(190, 100, 255))}, logo)
	tween(lg, {Rotation = 360}, 6, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1)
	make("TextLabel", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "F", Font = Enum.Font.GothamBlack, TextSize = 21, TextColor3 = Color3.new(1, 1, 1)}, logo)
	local tl = make("TextLabel", {Size = UDim2.new(0, 180, 0, 24), Position = UDim2.new(0, 60, 0, 8), BackgroundTransparency = 1, Text = "FEMBIIX",
		Font = Enum.Font.GothamBlack, TextSize = 21, TextColor3 = Color3.new(1, 1, 1), TextXAlignment = Enum.TextXAlignment.Left}, Head)
	make("UIGradient", {Color = ColorSequence.new({ColorSequenceKeypoint.new(0, C.text), ColorSequenceKeypoint.new(0.6, C.accent), ColorSequenceKeypoint.new(1, Color3.fromRGB(190, 100, 255))})}, tl)
	make("TextLabel", {Size = UDim2.new(0, 220, 0, 12), Position = UDim2.new(0, 61, 0, 33), BackgroundTransparency = 1, Text = "ADMIN  ·  WHITE EDITION  ·  v4",
		Font = Enum.Font.GothamBold, TextSize = 9, TextColor3 = C.dim, TextXAlignment = Enum.TextXAlignment.Left}, Head)
	local function pill(txt, x, w, col)
		local l = make("TextLabel", {Size = UDim2.fromOffset(w, 22), AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, x, 0, 17), BackgroundColor3 = C.el,
			Text = txt, Font = Enum.Font.GothamBold, TextSize = 11, TextColor3 = col, BorderSizePixel = 0}, Head)
		round(l, 11)
		return l
	end
	pill(DEVICE, -222, 78, C.accent)
	ui.fpsPill = pill("-- FPS", -306, 74, C.green)
	local function hb(txt, x, col)
		local b = make("TextButton", {Size = UDim2.fromOffset(30, 30), AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, x, 0, 13), BackgroundColor3 = col,
			Text = txt, TextColor3 = UIK.txt(col), Font = Enum.Font.GothamBold, TextSize = 14, AutoButtonColor = false, BorderSizePixel = 0}, Head)
		round(b, 10)
		b:SetAttribute("Base", col)
		attachHover(b)
		return b
	end
	local minB = hb("—", -52, C.el2)
	local closeB = hb("✕", -14, C.danger)
	local compB = hb("◧", -90, C.el2)
	local helpB = hb("⌨", -128, C.el2)
	local palB = hb("🔍", -166, C.el2)
	local panB = hb("⛔", -204, C.danger)
	compB.MouseButton1Click:Connect(function() UIK.setCompact(not UIK.compact) end)
	helpB.MouseButton1Click:Connect(function() UIK.showHelp() end)
	palB.MouseButton1Click:Connect(function() UIK.openPalette() end)
	panB.MouseButton1Click:Connect(function() API.panic() end)
	UIK.tip(compB, "Компактная панель: только иконки (удобно на телефоне)")
	UIK.tip(helpB, "Горячие клавиши")
	UIK.tip(palB, "Поиск по всему: режимы, небо, шляпы, действия (Ctrl+K или /)")
	UIK.tip(panB, "ПАНИКА: отпустить ракеты и спаркеры, остановить банан, вернуть камеру (End)")
	local line = make("Frame", {Size = UDim2.new(1, 0, 0, 2), Position = UDim2.new(0, 0, 0, 56), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0}, Win)
	local lgr = make("UIGradient", {Color = ColorSequence.new({ColorSequenceKeypoint.new(0, C.accent), ColorSequenceKeypoint.new(0.33, Color3.fromRGB(190, 100, 255)),
		ColorSequenceKeypoint.new(0.66, Color3.fromRGB(70, 200, 240)), ColorSequenceKeypoint.new(1, C.accent)}), Offset = Vector2.new(-1, 0)}, line)
	tween(lgr, {Offset = Vector2.new(1, 0)}, 3.5, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1)

	-- перетаскивание за шапку
	local dragging, dragStart, startPos
	Head.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging, dragStart, startPos = true, input.Position, MainFrame.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then dragging = false end
			end)
		end
	end)
	connect(UserInputService.InputChanged, function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local d = (input.Position - dragStart) / uiScale.Scale
			MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
		end
	end)

	-- боковая панель с вкладками и скользящим индикатором
	local side = make("Frame", {Size = UDim2.new(0, 176, 1, -86), Position = UDim2.new(0, 0, 0, 60), BackgroundTransparency = 1}, Win)
	UIK.ind = make("Frame", {Size = UDim2.new(1, -20, 0, 42), Position = UDim2.new(0, 10, 0, 10), BackgroundColor3 = C.accent, BorderSizePixel = 0}, side)
	round(UIK.ind, 12)
	make("UIGradient", {Color = ColorSequence.new(C.accent, Color3.fromRGB(150, 95, 255)), Rotation = 20}, UIK.ind)
	for i, tb in ipairs(TABS) do
		local y = 10 + (i - 1) * 46
		local b = make("TextButton", {Size = UDim2.new(1, -20, 0, 42), Position = UDim2.new(0, 10, 0, y), BackgroundColor3 = C.accent, BackgroundTransparency = 1,
			Text = "", AutoButtonColor = false, BorderSizePixel = 0}, side)
		round(b, 12)
		make("TextLabel", {Size = UDim2.fromOffset(30, 42), Position = UDim2.new(0, 10, 0, 0), BackgroundTransparency = 1, Text = tb[2], TextSize = 19}, b)
		local lbl = make("TextLabel", {Size = UDim2.new(1, -50, 1, 0), Position = UDim2.new(0, 44, 0, 0), BackgroundTransparency = 1, Text = tb[3],
			Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = C.text, TextXAlignment = Enum.TextXAlignment.Left}, b)
		b.MouseEnter:Connect(function() if currentTab ~= tb[1] then tween(b, {BackgroundTransparency = 0.88}, 0.12) end end)
		b.MouseLeave:Connect(function() tween(b, {BackgroundTransparency = 1}, 0.12) end)
		tabBtns[tb[1]] = {btn = b, lbl = lbl, y = y}
		b.MouseButton1Click:Connect(function() selectTab(tb[1]) end)
	end
	-- советы внизу панели
	ui.tip = make("TextLabel", {Size = UDim2.new(1, -24, 0, 54), AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 12, 1, -6), BackgroundColor3 = C.panel,
		Text = "💡 F — действие питомца, G — ехать к прицелу", TextColor3 = C.dim, Font = Enum.Font.GothamMedium, TextSize = 11, TextWrapped = true, BorderSizePixel = 0}, side)
	round(ui.tip, 12)
	stroke(ui.tip, Color3.fromRGB(226, 230, 244), 1, 0)

	-- область страниц + подвал
	pagesHolder = make("Frame", {Size = UDim2.new(1, -196, 1, -92), Position = UDim2.new(0, 186, 0, 66), BackgroundTransparency = 1, ClipsDescendants = true}, Win)
	local footer = make("TextLabel", {Size = UDim2.new(1, -200, 0, 18), Position = UDim2.new(0, 190, 1, -22), BackgroundTransparency = 1, Text = "",
		TextColor3 = C.dim, Font = Enum.Font.Gotham, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left}, Win)
	local fpsAcc, fpsN, tipT, tipI = 0, 0, 0, 1
	local TIPS = {"💡 F — действие питомца, G — ехать к прицелу", "💡 RightShift или H — скрыть окно", "💡 «Мир» → Хэллоуинская ночь и шляпы",
		"💡 Спаркеры: режим «Надпись» пишет FEMBIIX", "💡 Дракон: поставь 12–30 ракет и включи кино-камеру", "💡 Спутники: ракеты кружат вокруг игрока"}
	function ui.footerTick(dt)
		fpsAcc += dt; fpsN += 1; tipT += dt
		if fpsAcc >= 0.5 then
			local fps = math.floor(fpsN / fpsAcc + 0.5)
			fpsAcc, fpsN = 0, 0
			ui.fpsPill.Text = fps .. " FPS"
			ui.fpsPill.TextColor3 = (fps >= 50) and C.green or ((fps >= 30) and C.gold or C.danger)
			footer.Text = ("%s · ракет %d · спаркеров %d · Fembiix v4 Admin White"):format(DEVICE, #swarmRockets, #sparklers)
		end
		if tipT > 7 then
			tipT = 0
			tipI = tipI % #TIPS + 1
			ui.tip.Text = TIPS[tipI]
		end
	end

	function UIK.setCompact(on)
		UIK.compact = on and true or false
		API.cfg.compact = UIK.compact
		API.save()
		local w = on and 64 or 176
		tween(side, {Size = UDim2.new(0, w, 1, -86)}, 0.25, Enum.EasingStyle.Cubic)
		for _, t in pairs(tabBtns) do t.lbl.Visible = not on end
		ui.tip.Visible = not on
		tween(pagesHolder, {Position = UDim2.new(0, w + 10, 0, 66), Size = UDim2.new(1, -(w + 20), 1, -92)}, 0.25, Enum.EasingStyle.Cubic)
		footer.Position = UDim2.new(0, w + 14, 1, -22)
	end
	if API.cfg.compact ~= nil then UIK.setCompact(API.cfg.compact) elseif DEVICE == "ТЕЛЕФОН" then UIK.setCompact(true) end

	-- сворачивание / закрытие
	local minimized = false
	minB.MouseButton1Click:Connect(function()
		minimized = not minimized
		tween(Win, {Size = minimized and UDim2.new(1, 0, 0, 58) or UDim2.fromScale(1, 1)}, 0.28, Enum.EasingStyle.Quart)
		for _, s in ipairs(UIK.shadows) do s.Visible = not minimized end
	end)

	-- кнопка-иконка, когда окно скрыто
	bubble = make("TextButton", {Size = UDim2.fromOffset(54, 54), Position = UDim2.new(0, 14, 0.5, -27), BackgroundColor3 = Color3.new(1, 1, 1), AutoButtonColor = false,
		Text = "F", TextColor3 = C.accent, Font = Enum.Font.GothamBlack, TextSize = 24, Visible = false, BorderSizePixel = 0, ZIndex = 20}, screenGui)
	round(bubble, 27)
	stroke(bubble, C.accent, 2, 0.1)
	local bs = make("UIScale", {Scale = 1}, bubble)
	tween(bs, {Scale = 1.08}, 1.1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
	bubble.MouseEnter:Connect(function() overBubble = true end)
	bubble.MouseLeave:Connect(function() overBubble = false end)

	hidden = false
	setHidden = function(h)
		hidden = h
		bubble.Visible = h
		if h then
			MainFrame.Visible = false
			overMain = false
		else
			overBubble = false
			MainFrame.Visible = true
			uiScale.Scale = userScale * 0.85
			tween(uiScale, {Scale = userScale}, 0.35, Enum.EasingStyle.Back)
		end
	end
	closeB.MouseButton1Click:Connect(function() setHidden(true) end)
	bubble.MouseButton1Click:Connect(function() setHidden(false) end)
	connect(UserInputService.InputBegan, function(input, processed)
		if processed or introActive then return end
		if input.KeyCode == Enum.KeyCode.RightShift or input.KeyCode == Enum.KeyCode.H then
			setHidden(not hidden)
		elseif input.KeyCode == Enum.KeyCode.End then
			API.panic()
		elseif input.KeyCode == Enum.KeyCode.Slash or (input.KeyCode == Enum.KeyCode.K and (UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.RightControl))) then
			UIK.openPalette()
		elseif (input.KeyCode == Enum.KeyCode.LeftBracket or input.KeyCode == Enum.KeyCode.RightBracket) and MainFrame.Visible then
			local idx = 1
			for i, tb in ipairs(TABS) do
				if tb[1] == currentTab then idx = i end
			end
			idx = idx + ((input.KeyCode == Enum.KeyCode.RightBracket) and 1 or -1)
			selectTab(TABS[(idx - 1) % #TABS + 1][1])
		elseif API.onKey(input.KeyCode) then
			-- обработано в API
		end
	end)

	selectTab = function(name, instant)
		local changed = (currentTab ~= name)
		for key, page in pairs(pages) do
			if key == name then
				page.Visible = true
				if not instant and changed then
					page.Position = UDim2.new(0, 30, 0, 0)
					tween(page, {Position = UDim2.new(0, 0, 0, 0)}, 0.28, Enum.EasingStyle.Cubic)
				end
			else
				page.Visible = false
			end
		end
		for key, t in pairs(tabBtns) do
			local on = (key == name)
			tween(t.lbl, {TextColor3 = on and Color3.new(1, 1, 1) or C.text}, 0.15)
			if on then tween(UIK.ind, {Position = UDim2.new(0, 10, 0, t.y)}, instant and 0.01 or 0.3, Enum.EasingStyle.Back) end
		end
		currentTab = name
		API.cfg.lastTab = name
		API.save()
		if changed then
			if name == "rockets" and ui.activateManual then ui.activateManual()
			elseif name == "swarm" and ui.activatePet then ui.activatePet() end
		end
	end
end

-- ---------- конструкторы страниц и элементов (белая тема) ----------
local function scrollList(parent, size, pos)
	local sf = make("ScrollingFrame", {Size = size, Position = pos or UDim2.new(), BackgroundTransparency = 1, BorderSizePixel = 0,
		ScrollBarThickness = 4, ScrollBarImageColor3 = C.accent, ScrollBarImageTransparency = 0.3, CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y}, parent)
	make("UIListLayout", {Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder}, sf)
	make("UIPadding", {PaddingTop = UDim.new(0, 2), PaddingBottom = UDim.new(0, 8), PaddingLeft = UDim.new(0, 2), PaddingRight = UDim.new(0, 10)}, sf)
	return sf
end

local function newSplitPage(name)
	local page = make("Frame", {Name = name, Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Visible = false}, pagesHolder)
	local left = make("Frame", {Size = UDim2.new(0, 196, 1, -2), BackgroundColor3 = C.panel, BorderSizePixel = 0}, page)
	round(left, 14)
	stroke(left, Color3.fromRGB(226, 230, 244), 1, 0)
	local right = scrollList(page, UDim2.new(1, -206, 1, 0), UDim2.new(0, 206, 0, 0))
	pages[name] = page
	return left, right
end

UIK.listN = 0
local function buildModeList(left, modes, onSelect)
	UIK.listN += 1
	local lid = UIK.listN
	local search = make("TextBox", {Size = UDim2.new(1, -16, 0, 30), Position = UDim2.new(0, 8, 0, 8), BackgroundColor3 = C.el,
		PlaceholderText = "🔍 Поиск режима  ·  ☆ — в избранное", PlaceholderColor3 = C.dim, Text = "", TextColor3 = C.text, ClearTextOnFocus = false,
		Font = Enum.Font.GothamMedium, TextSize = 12, BorderSizePixel = 0}, left)
	round(search, 10)
	local list = make("ScrollingFrame", {Size = UDim2.new(1, 0, 1, -48), Position = UDim2.new(0, 0, 0, 46), BackgroundTransparency = 1,
		BorderSizePixel = 0, ScrollBarThickness = 3, ScrollBarImageColor3 = C.accent, CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y}, left)
	make("UIListLayout", {Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder}, list)
	make("UIPadding", {PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 10), PaddingBottom = UDim.new(0, 8)}, list)
	local buttons, rows, lowered = {}, {}, {}
	for i, m in ipairs(modes) do
		local fk = lid .. ":" .. m.key
		local row = make("Frame", {Size = UDim2.new(1, 0, 0, 34 + UIK.thv), BackgroundTransparency = 1, LayoutOrder = i}, list)
		local b = make("TextButton", {Size = UDim2.new(1, -28, 1, 0), BackgroundColor3 = C.el, AutoButtonColor = false, Text = m.label,
			TextColor3 = C.text, Font = Enum.Font.GothamMedium, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left,
			BorderSizePixel = 0, TextTruncate = Enum.TextTruncate.AtEnd}, row)
		round(b, 10)
		make("UIPadding", {PaddingLeft = UDim.new(0, 10)}, b)
		b:SetAttribute("Base", C.el)
		attachHover(b)
		UIK.tip(b, m.label .. "\n" .. (m.desc or ""))
		b.MouseButton1Click:Connect(function() onSelect(m.key) end)
		local star = make("TextButton", {Size = UDim2.fromOffset(26, 26), AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0),
			BackgroundTransparency = 1, Text = "☆", TextSize = 17, TextColor3 = C.dim, AutoButtonColor = false}, row)
		local function paintStar()
			local on = API.cfg.fav[fk] == true
			star.Text = on and "★" or "☆"
			star.TextColor3 = on and C.gold or C.dim
			row.LayoutOrder = on and (i - 10000) or i -- избранное поднимается наверх
		end
		star.MouseButton1Click:Connect(function()
			API.cfg.fav[fk] = (API.cfg.fav[fk] ~= true) or nil
			API.save()
			paintStar()
		end)
		paintStar()
		buttons[m.key], rows[m.key] = b, row
		lowered[m.key] = ulower(m.label) .. " " .. m.key:lower()
	end
	search:GetPropertyChangedSignal("Text"):Connect(function()
		local q = ulower(search.Text)
		for key, row in pairs(rows) do
			row.Visible = (q == "") or (lowered[key]:find(q, 1, true) ~= nil)
		end
	end)
	return function(selected)
		for key, b in pairs(buttons) do setBase(b, key == selected and C.accentDark or C.el) end
	end
end

local function card(parent, order)
	local f = make("Frame", {Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = C.panel,
		BorderSizePixel = 0, LayoutOrder = order}, parent)
	round(f, 12)
	stroke(f, Color3.fromRGB(226, 230, 244), 1, 0)
	make("UIListLayout", {Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.LayoutOrder}, f)
	make("UIPadding", {PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10), PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12)}, f)
	return f
end
local function cardText(parent, text, size, color, font, order)
	return make("TextLabel", {Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1,
		Text = text, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
		TextSize = size, TextColor3 = color, Font = font, LayoutOrder = order or 0}, parent)
end

local function slider(parent, scroll, name, min, max, default, step, order, onChange)
	local holder = make("Frame", {Size = UDim2.new(1, 0, 0, 52), BackgroundColor3 = C.panel, BorderSizePixel = 0, LayoutOrder = order}, parent)
	round(holder, 12)
	stroke(holder, Color3.fromRGB(226, 230, 244), 1, 0)
	local nameLbl = make("TextLabel", {Size = UDim2.new(1, -90, 0, 20), Position = UDim2.new(0, 12, 0, 6), BackgroundTransparency = 1,
		Text = name, TextColor3 = C.text, Font = Enum.Font.GothamMedium, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd}, holder)
	local valLbl = make("TextLabel", {Size = UDim2.fromOffset(60, 20), AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -10, 0, 6),
		BackgroundColor3 = C.el, Text = "", TextColor3 = C.accent, Font = Enum.Font.GothamBold, TextSize = 12, BorderSizePixel = 0}, holder)
	round(valLbl, 8)
	local track = make("Frame", {Size = UDim2.new(1, -24, 0, 6), Position = UDim2.new(0, 12, 0, 37), BackgroundColor3 = C.off, BorderSizePixel = 0}, holder)
	round(track, 3)
	local fill = make("Frame", {BackgroundColor3 = C.accent, BorderSizePixel = 0, Size = UDim2.new(0, 0, 1, 0)}, track)
	round(fill, 3)
	make("UIGradient", {Color = ColorSequence.new(C.accent, Color3.fromRGB(170, 105, 255))}, fill)
	local knob = make("Frame", {Size = UDim2.fromOffset(18, 18), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0, 0, 0.5, 0),
		BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0}, track)
	round(knob, 9)
	stroke(knob, C.accent, 2, 0)
	local ks = make("UIScale", {Scale = 1}, knob)
	local hit = make("TextButton", {Size = UDim2.new(1, 0, 0, 44), Position = UDim2.new(0, 0, 0.5, -22), BackgroundTransparency = 1, Text = ""}, track)

	local value = default
	local function render()
		local r = (value - min) / (max - min)
		fill.Size = UDim2.new(r, 0, 1, 0)
		knob.Position = UDim2.new(r, 0, 0.5, 0)
		valLbl.Text = tostring(value)
	end
	local function setValue(v, fire)
		v = math.clamp(math.floor(v / step + 0.5) * step, min, max)
		value = math.floor(v * 1000 + 0.5) / 1000
		render()
		if fire and onChange then onChange(value) end
	end
	local function fromX(x)
		setValue(min + (max - min) * math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1), true)
	end
	local dragging = false
	hit.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			scroll.ScrollingEnabled = false
			tween(ks, {Scale = 1.22}, 0.1)
			fromX(input.Position.X)
		end
	end)
	connect(UserInputService.InputChanged, function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			fromX(input.Position.X)
		end
	end)
	connect(UserInputService.InputEnded, function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
			dragging = false
			scroll.ScrollingEnabled = true
			tween(ks, {Scale = 1}, 0.15, Enum.EasingStyle.Back)
		end
	end)
	render()
	return {
		Get = function() return value end,
		Set = function(v) setValue(v, false) end,
		SetName = function(n) nameLbl.Text = n end,
	}
end

local function toggle(parent, text, default, order, cb)
	local row = make("Frame", {Size = UDim2.new(1, 0, 0, 40), BackgroundColor3 = C.panel, BorderSizePixel = 0, LayoutOrder = order}, parent)
	round(row, 12)
	stroke(row, Color3.fromRGB(226, 230, 244), 1, 0)
	make("TextLabel", {Size = UDim2.new(1, -74, 1, 0), Position = UDim2.new(0, 12, 0, 0), BackgroundTransparency = 1, Text = text, TextWrapped = true,
		TextColor3 = C.text, Font = Enum.Font.GothamMedium, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left}, row)
	local sw = make("TextButton", {Size = UDim2.fromOffset(46, 24), Position = UDim2.new(1, -58, 0.5, -12), Text = "", AutoButtonColor = false,
		BackgroundColor3 = C.off, BorderSizePixel = 0}, row)
	round(sw, 12)
	local knob = make("Frame", {Size = UDim2.fromOffset(20, 20), Position = UDim2.new(0, 2, 0.5, -10), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0}, sw)
	round(knob, 10)
	stroke(knob, Color3.new(0, 0, 0), 1, 0.88)
	local state = default
	local function render()
		tween(sw, {BackgroundColor3 = state and C.accent or C.off}, 0.15)
		tween(knob, {Position = state and UDim2.new(1, -22, 0.5, -10) or UDim2.new(0, 2, 0.5, -10)}, 0.18, Enum.EasingStyle.Back)
	end
	sw.MouseButton1Click:Connect(function() state = not state; render(); cb(state) end)
	render()
	return {Set = function(v) state = v; render() end}
end

-- ---------- ВКЛАДКА: РАКЕТА (одиночная) ----------
do
	local left, right = newSplitPage("rockets")
	local highlight = buildModeList(left, ROCKET_MODES, function(key) ui.selectRocketMode(key) end)

	local info = card(right, 1)
	ui.rkTitle = cardText(info, "", 16, C.accent, Enum.Font.GothamBlack, 1)
	ui.rkDesc = cardText(info, "", 12, C.dim, Enum.Font.GothamMedium, 2)
	local st = card(right, 2)
	ui.rkStatus = cardText(st, "Статус: ищу ракету (BombMissile) рядом…", 12, C.text, Enum.Font.GothamBold)

	ui.rkSpeed = slider(right, right, "Скорость", 0, 800, 90, 5, 3)
	ui.rkRadius = slider(right, right, "Радиус", 5, 150, 40, 1, 4)
	ui.rkParam = slider(right, right, "Доп. параметр", 1, 80, 15, 1, 5)

	ui.viewBtn = button(right, "📷 ВИД: 3-Е ЛИЦО", C.accentDark, 6)
	ui.freecamBtn = button(right, "👁 ОБЗОР: ВЫКЛ", C.el2, 7)

	ui.patrolRow = make("Frame", {Size = UDim2.new(1, 0, 0, 34), BackgroundTransparency = 1, LayoutOrder = 8, Visible = false}, right)
	ui.patrolAdd = button(ui.patrolRow, "➕ Точка (0)", C.green, 0)
	ui.patrolAdd.Size = UDim2.new(0.49, 0, 1, 0)
	ui.patrolClear = button(ui.patrolRow, "🗑 Очистить", C.danger, 0)
	ui.patrolClear.Size = UDim2.new(0.49, 0, 1, 0)
	ui.patrolClear.Position = UDim2.new(0.51, 0, 0, 0)

	ui.cancelBtn = button(right, "ОТВЯЗАТЬ КАМЕРУ", C.danger, 9, 36)

	function ui.selectRocketMode(key)
		rocketModeKey = key
		local m = ROCKET_BY_KEY[key]
		ui.rkTitle.Text = m.label
		ui.rkDesc.Text = m.desc
		ui.rkParam.SetName(m.param)
		ui.patrolRow.Visible = (key == "PATROL")
		highlight(key)
		modeSwitchReset = true
	end

	ui.viewBtn.MouseButton1Click:Connect(function()
		isFirstPerson = not isFirstPerson
		ui.viewBtn.Text = isFirstPerson and "📷 ВИД: 1-Е ЛИЦО" or "📷 ВИД: 3-Е ЛИЦО"
		setBase(ui.viewBtn, isFirstPerson and C.accent or C.accentDark)
	end)
	ui.freecamBtn.MouseButton1Click:Connect(function() setFreecam(not isFreecam) end)
	ui.patrolAdd.MouseButton1Click:Connect(function()
		if mainPart then
			table.insert(waypoints, mainPart.Position)
			ui.patrolAdd.Text = "➕ Точка (" .. #waypoints .. ")"
		end
	end)
	ui.patrolClear.MouseButton1Click:Connect(function()
		waypoints, patrolIndex = {}, 1
		ui.patrolAdd.Text = "➕ Точка (0)"
	end)
	ui.cancelBtn.MouseButton1Click:Connect(cancelRocket)
end

-- ---------- ВКЛАДКА: МОЯ ХОДЯЧАЯ РАКЕТА ----------
do
	local BANNER_Y = 0.14 -- высота баннера «Бобик, фас!» (0 — верх экрана; не по центру)
	local left, right = newSplitPage("swarm")
	local highlight = buildModeList(left, SWARM_MODES, function(key) ui.selectSwarmMode(key) end)

	local info = card(right, 1)
	ui.swTitle = cardText(info, "", 16, C.accent, Enum.Font.GothamBlack, 1)
	ui.swDesc = cardText(info, "", 12, C.dim, Enum.Font.GothamMedium, 2)
	local st = card(right, 2)
	ui.swStatus = cardText(st, "Питомец выключен", 12, C.text, Enum.Font.GothamBold, 1)
	cardText(st, "Питомец включается сам, пока открыта эта вкладка. Вкладка «Ручная» возвращает обычный запуск ракеты.", 11, C.dim, Enum.Font.Gotham, 2)

	ui.swCount = slider(right, right, "Количество ракет", 1, 30, 5, 1, 3)
	ui.rideSpeed = slider(right, right, "Скорость катания", 20, 300, 90, 5, 4)
	ui.bobSpeed = slider(right, right, "Скорость Бобика", 100, 800, 400, 10, 5)
	ui.barkVol = slider(right, right, "🔊 Громкость лая", 0, 10, 8, 0.5, 5)
	ui.followDist = slider(right, right, "📏 Дистанция сзади", 3, 14, 6, 1, 5)
	ui.safeR = slider(right, right, "🛡 Безопасная зона вокруг меня", 6, 30, 12, 1, 5)
	ui.swSpeed = slider(right, right, "Скорость залпа", 20, 600, 160, 5, 6)
	ui.swRadius = slider(right, right, "Радиус залпа", 5, 120, 35, 1, 7)
	ui.swDist = slider(right, right, "Дальность прицела", 20, 500, 120, 5, 8)
	toggle(right, "Авто-захват рядом", true, 9, function(v) swarmAuto = v end)
	toggle(right, "Залп: телепорт на стороны", false, 10, function(v) swarmTeleport = v end)
	toggle(right, "🛡 Ракеты не толкают меня", true, 10, function(v) API.noPush = v end)
	toggle(right, "🔊 Лай при атаке", true, 10, function(v) API.barkOn = v end)
	toggle(right, "✨ Подсветка цели", true, 10, function(v) API.hlOn = v end)
	toggle(right, "🛡 Защита от самоподрыва", true, 10, function(v) API.selfGuard = v end)
	toggle(right, "🎥 Кино-камера дракона", false, 10, function(v) API.dragonCam = v end)

	ui.swSpawn = button(right, "➕ ЗАСПАВНИТЬ РАКЕТЫ", C.green, 11)
	ui.swCapture = button(right, "🎯 ЗАХВАТИТЬ БЛИЖАЙШИЕ", C.el2, 12)
	ui.swLaunch = button(right, "🐕 ПРОСТО ГУЛЯЕМ", C.accentDark, 13, 40)
	ui.swGive = button(right, "🎁 ОТДАТЬ РАКЕТУ ИГРОКУ (в прицеле / рядом)", C.el2, 14)
	ui.swTake = button(right, "↩ ЗАБРАТЬ ВСЕХ ОБРАТНО", C.el2, 15)
	ui.swRelease = button(right, "💨 ОТПУСТИТЬ ВСЕХ", C.danger, 16)

	-- звук лая: в SoundService, поэтому слышит только отправитель
	ui.bark = make("Sound", {Name = "FembiixBark", SoundId = "rbxassetid://83588491479535", Volume = 2, Looped = true}, game:GetService("SoundService"))

	-- подсказка «Бобик»
	ui.hintBobik = make("TextLabel", {Size = UDim2.new(0, 470, 0, 34), AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 84),
		BackgroundColor3 = C.bg, BackgroundTransparency = 0.15, TextColor3 = C.accent, Font = Enum.Font.GothamBold, TextSize = 14,
		Text = "🐶 Наведи кружок на игрока и жми F ещё раз · X — отмена", Visible = false}, screenGui)
	round(ui.hintBobik, 10)
	stroke(ui.hintBobik, C.accent, 1.5, 0.2)

	ui.aimLabel = make("TextLabel", {Size = UDim2.new(0, 260, 0, 18), AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 1, 8),
		BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = Color3.new(1, 1, 1),
		TextStrokeColor3 = Color3.new(0, 0, 0), TextStrokeTransparency = 0.3, Text = ""}, ui.aim)

	-- кнопки катания
	ui.rideBar = make("Frame", {Size = UDim2.new(0, 236, 0, 52), AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 16, 1, -110),
		BackgroundTransparency = 1, Visible = false}, screenGui)
	make("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8)}, ui.rideBar)
	local function rideBtn(txt, onDown, onUp)
		local b = make("TextButton", {Size = UDim2.new(0, 52, 0, 52), BackgroundColor3 = C.panel, Text = txt, TextSize = 22,
			AutoButtonColor = false, BorderSizePixel = 0}, ui.rideBar)
		round(b, 12)
		stroke(b, C.accent, 2, 0.2)
		b.InputBegan:Connect(function(i)
			if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then onDown() end
		end)
		b.InputEnded:Connect(function(i)
			if onUp and (i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch) then onUp() end
		end)
		return b
	end
	rideBtn("⬆", function() API.rideHold("up", true) end, function() API.rideHold("up", false) end)
	rideBtn("⬇", function() API.rideHold("down", true) end, function() API.rideHold("down", false) end)
	rideBtn("🎯", function() API.rideGoAim() end)
	rideBtn("🛑", function() API.dismount() end)

	-- баннер «Бобик, фас!»: влетает сверху-справа от центра, бьёт, трясётся, улетает
	function ui.bobikBanner(name)
		name = tostring(name or "?")
		if #name > 20 then name = name:sub(1, 20) end
		local sc = math.clamp(camera.ViewportSize.X / 900, 0.6, 1)
		local f = make("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(-0.3, 0, BANNER_Y, 0), Size = UDim2.new(0, 480, 0, 92),
			BackgroundColor3 = Color3.fromRGB(110, 12, 12), BorderSizePixel = 0, ZIndex = 60}, screenGui)
		round(f, 16)
		local st2 = stroke(f, Color3.fromRGB(255, 80, 40), 3, 0)
		make("UIGradient", {Color = ColorSequence.new(Color3.fromRGB(190, 25, 20), Color3.fromRGB(60, 6, 6))}, f)
		make("UIScale", {Scale = sc}, f)
		local dog = make("TextLabel", {Size = UDim2.new(0, 80, 1, 0), Position = UDim2.new(0, 8, 0, 0), BackgroundTransparency = 1,
			Text = "🐶", TextSize = 58, ZIndex = 61}, f)
		make("TextLabel", {Size = UDim2.new(1, -100, 0, 52), Position = UDim2.new(0, 92, 0, 6), BackgroundTransparency = 1,
			Text = "БОБИК, ФАС!", Font = Enum.Font.GothamBlack, TextSize = 40, TextColor3 = Color3.new(1, 1, 1),
			TextStrokeColor3 = Color3.fromRGB(60, 0, 0), TextStrokeTransparency = 0, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 61}, f)
		make("TextLabel", {Size = UDim2.new(1, -100, 0, 24), Position = UDim2.new(0, 94, 0, 58), BackgroundTransparency = 1,
			Text = "🎯 цель: " .. name, Font = Enum.Font.GothamBold, TextSize = 15, TextColor3 = Color3.fromRGB(255, 210, 160),
			TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 61}, f)
		tween(f, {Position = UDim2.new(0.5, 0, BANNER_Y, 0)}, 0.35, Enum.EasingStyle.Back)
		tween(dog, {Rotation = 14}, 0.12, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
		tween(st2, {Thickness = 7, Transparency = 0.5}, 0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
		task.spawn(function()
			task.wait(0.4)
			for _ = 1, 8 do
				if not f.Parent then return end
				f.Position = UDim2.new(0.5, math.random(-8, 8), BANNER_Y, math.random(-6, 6))
				task.wait(0.03)
			end
			f.Position = UDim2.new(0.5, 0, BANNER_Y, 0)
			task.wait(1.3)
			tween(f, {Position = UDim2.new(1.4, 0, BANNER_Y, 0)}, 0.35, Enum.EasingStyle.Back, Enum.EasingDirection.In)
			task.wait(0.4)
			f:Destroy()
		end)
	end

	function ui.selectSwarmMode(key)
		API.dismount()
		API.bobikCancel()
		API.setSwarmLaunched(false)
		swarmModeKey = key
		local m = SWARM_BY_KEY[key]
		ui.swTitle.Text = m.label
		ui.swDesc.Text = m.desc
		highlight(key)
		swarmT0 = os.clock()
		API.refreshActionUi()
	end
	-- переключение вкладок = переключение системы ракет (чтобы они не мешали друг другу)
	function ui.activateManual() API.setSwarmEnabled(false) end
	function ui.activatePet() API.setSwarmEnabled(true) end

	ui.swSpawn.MouseButton1Click:Connect(function()
		API.setSwarmEnabled(true)
		API.spawnRockets(ui.swCount.Get())
	end)
	ui.swCapture.MouseButton1Click:Connect(function()
		API.setSwarmEnabled(true)
		if API.captureSwarm() == 0 then notify("Рядом нет свободных BombMissile", C.danger) end
	end)
	ui.swLaunch.MouseButton1Click:Connect(function() API.petAction() end)
	ui.swGive.MouseButton1Click:Connect(function() API.giveRocket() end)
	ui.swTake.MouseButton1Click:Connect(function() API.takeAllBack() end)
	ui.swRelease.MouseButton1Click:Connect(function()
		API.setSwarmLaunched(false)
		API.releaseAllSwarm()
		notify("💨 Ракеты отпущены")
	end)
end

-- ---------- ВКЛАДКА: СПАРКЕРЫ ----------
do
	local left, right = newSplitPage("sparklers")
	local highlight = buildModeList(left, SPARK_MODES, function(key) ui.selectSparkMode(key) end)

	local info = card(right, 1)
	ui.spTitle = cardText(info, "", 16, C.accent, Enum.Font.GothamBlack, 1)
	ui.spDesc = cardText(info, "", 12, C.dim, Enum.Font.GothamMedium, 2)
	local st = card(right, 2)
	ui.spStatus = cardText(st, "Захвачено: 0 / 10", 13, C.text, Enum.Font.GothamBold)
	cardText(st, "Подойди к FireworkSparkler, и он присоединится.", 11, C.dim, Enum.Font.Gotham, 2)

	ui.spCount = slider(right, right, "Макс. количество", 1, 10, 10, 1, 3)
	ui.spRadius = slider(right, right, "Радиус / размер", 2, 25, 8, 1, 4)
	ui.spHeight = slider(right, right, "Высота", -3, 15, 3, 1, 5)
	ui.spSpin = slider(right, right, "Скорость вращения", 0, 10, 2, 0.1, 6)
	ui.spResp = slider(right, right, "Отклик (резкость)", 5, 100, 35, 1, 7)

	ui.autoToggle = toggle(right, "Авто-захват рядом", true, 8, function(v) autoCapture = v end)
	toggle(right, "Эффект искр и свет", true, 9, function(v) sparkFx = v; applyFx() end)
	toggle(right, "Шлейф за огнями", true, 10, function(v) sparkTrail = v; applyFx() end)
	toggle(right, "Радужные цвета", true, 11, function(v) sparkRainbow = v end)

	do
		local row = make("Frame", {Size = UDim2.new(1, 0, 0, 40), BackgroundColor3 = C.el, BorderSizePixel = 0, LayoutOrder = 12}, right)
		round(row, 8)
		make("TextLabel", {Size = UDim2.new(0.38, 0, 1, 0), Position = UDim2.new(0, 10, 0, 0), BackgroundTransparency = 1,
			Text = "✍ Текст надписи", TextColor3 = C.text, Font = Enum.Font.GothamMedium, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left}, row)
		local tb = make("TextBox", {Size = UDim2.new(0.58, -10, 0, 26), Position = UDim2.new(0.4, 0, 0.5, -13), BackgroundColor3 = C.el2,
			Text = TXT.text, PlaceholderText = "FEMBIIX", PlaceholderColor3 = C.dim, TextColor3 = C.text, ClearTextOnFocus = false,
			Font = Enum.Font.GothamBold, TextSize = 13, BorderSizePixel = 0}, row)
		round(tb, 6)
		tb.FocusLost:Connect(function()
			local t = tb.Text
			if t:gsub("%s", "") == "" or utf8.len(t) == nil then t = "FEMBIIX" end
			TXT.text = t
			tb.Text = t
			notify("✍ Надпись: " .. t)
		end)
	end
	local capBtn = button(right, "🎆 ЗАХВАТИТЬ БЛИЖАЙШИЕ", C.green, 13)
	local relBtn = button(right, "💨 ОТПУСТИТЬ ВСЕХ", C.danger, 14)
	capBtn.MouseButton1Click:Connect(function() captureNearby() end)
	relBtn.MouseButton1Click:Connect(function()
		releaseAllSparklers()
		autoCapture = false
		ui.autoToggle.Set(false)
	end)

	function ui.selectSparkMode(key)
		sparkModeKey = key
		local m = SPARK_BY_KEY[key]
		ui.spTitle.Text = m.label
		ui.spDesc.Text = m.desc
		highlight(key)
		tail = {}
		sparkMorph = true
	end
end

-- ---------- ВКЛАДКА: МИР И КАМЕРА ----------
do
	local Lighting = game:GetService("Lighting")
	local page = scrollList(pagesHolder, UDim2.fromScale(1, 1))
	page.Name = "world"
	page.Visible = false
	pages.world = page
	local WD = {on = false, snap = nil, cam = nil, stash = {}, hatParts = {}, hatKey = "NONE", hatScale = 1, fovOn = false, fov = 70,
		lightning = false, nextBolt = 0, flashUntil = 0, flashing = false, partRate = 40, sl = {}}
	local order = 0
	local function nx() order += 1; return order end
	local function c3(r, g, b) return Color3.fromRGB(r, g, b) end

	-- ---------- освещение: снимок, замена неба, восстановление ----------
	local PROPS = {"Ambient", "OutdoorAmbient", "Brightness", "ClockTime", "FogColor", "FogEnd", "FogStart", "ExposureCompensation", "GlobalShadows"}
	local function ensure(class, name)
		local o = Lighting:FindFirstChild(name)
		if not o then
			o = Instance.new(class)
			o.Name = name
			o.Parent = Lighting
		end
		return o
	end
	local function touch()
		if WD.on then return end
		WD.snap = {}
		for _, k in ipairs(PROPS) do WD.snap[k] = Lighting[k] end
		for _, ch in ipairs(Lighting:GetChildren()) do -- родное небо/атмосферу игры убираем на время
			if (ch:IsA("Sky") or ch:IsA("Atmosphere")) and ch.Name:sub(1, 7) ~= "Fembiix" then
				table.insert(WD.stash, ch)
				ch.Parent = nil
			end
		end
		WD.on = true
	end

	-- ---------- погода-частицы вокруг игрока ----------
	local function setParticles(cfg)
		if WD.pPart then WD.pPart:Destroy() end
		WD.pPart, WD.emitter, WD.pCfg = nil, nil, cfg
		if not cfg then return end
		WD.pPart = make("Part", {Name = "FembiixWeather", Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false, Transparency = 1, Size = Vector3.new(90, 1, 90)}, camera)
		WD.emitter = make("ParticleEmitter", {
			Rate = WD.partRate, Lifetime = NumberRange.new(5, 9), Speed = NumberRange.new(cfg[3] * 0.6, cfg[3]), SpreadAngle = Vector2.new(25, 25),
			LightEmission = 0.8, Color = ColorSequence.new(cfg[1]), Rotation = NumberRange.new(0, 360),
			Size = NumberSequence.new({NumberSequenceKeypoint.new(0, cfg[4]), NumberSequenceKeypoint.new(1, 0)}),
			Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1)}),
			Shape = Enum.ParticleEmitterShape.Box, ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume,
			EmissionDirection = cfg[2] and Enum.NormalId.Top or Enum.NormalId.Bottom, Acceleration = Vector3.new(0, cfg[2] and 1 or -1, 0),
		}, WD.pPart)
	end
	local function restore()
		for _, n in ipairs({"FembiixSky", "FembiixAtmo", "FembiixCC", "FembiixBloom", "FembiixRays"}) do
			local o = Lighting:FindFirstChild(n)
			if o then o:Destroy() end
		end
		for _, ch in ipairs(WD.stash) do pcall(function() ch.Parent = Lighting end) end
		WD.stash = {}
		if WD.snap then
			for k, v in pairs(WD.snap) do pcall(function() Lighting[k] = v end) end
		end
		WD.snap, WD.on, WD.flashing = nil, false, false
		setParticles(nil)
	end

	-- ---------- пресеты неба ----------
	local function P(name, clock, bright, amb, out, fogC, fogS, fogE, at, cc, bl, rays, stars, moon, sun, part)
		return {name = name, clock = clock, bright = bright, amb = amb, out = out, fogC = fogC, fogS = fogS, fogE = fogE, at = at, cc = cc, bl = bl, rays = rays, stars = stars, moon = moon, sun = sun, part = part}
	end
	local PRESETS = {
		P("🎃 Хэллоуинская ночь", 0, 1.3, c3(70, 30, 90), c3(80, 40, 100), c3(70, 25, 80), 20, 700, {0.42, c3(255, 120, 40), c3(120, 40, 140), 0.6, 2.2}, {c3(255, 200, 170), 0.15, 0.15, -0.03}, {0.9, 28, 0.85}, 0.12, 3000, 30, 8, {c3(255, 140, 30), true, 6, 0.35}),
		P("🌕 Кровавая луна", 0, 1, c3(80, 20, 20), c3(90, 25, 25), c3(90, 10, 10), 10, 500, {0.5, c3(255, 60, 40), c3(140, 10, 10), 1, 2.5}, {c3(255, 150, 140), 0.1, 0.2, -0.05}, {1.1, 30, 0.8}, 0.05, 4000, 48, 6, {c3(255, 60, 40), true, 5, 0.3}),
		P("🔥 Ад", 0, 1.4, c3(110, 35, 15), c3(130, 45, 20), c3(120, 30, 10), 10, 450, {0.5, c3(255, 100, 30), c3(160, 40, 10), 1, 2.8}, {c3(255, 180, 140), 0.3, 0.25, -0.02}, {1.4, 32, 0.75}, 0.1, 500, 10, 6, {c3(255, 120, 30), true, 8, 0.4}),
		P("🌌 Космос", 0, 0.6, c3(25, 30, 60), c3(35, 40, 80), c3(10, 10, 25), 200, 4000, {0, c3(100, 120, 200), c3(60, 70, 120), 0, 0}, {c3(220, 230, 255), 0.2, 0.25, 0}, {0.7, 24, 0.9}, 0, 5000, 20, 10, nil),
		P("❄ Ледяная ночь", 1, 1, c3(40, 60, 100), c3(50, 75, 120), c3(30, 50, 90), 30, 700, {0.4, c3(150, 200, 255), c3(90, 130, 190), 0.4, 1.8}, {c3(190, 220, 255), 0.1, 0.15, 0}, {0.8, 26, 0.9}, 0, 4000, 26, 8, {c3(240, 248, 255), false, 4, 0.4}),
		P("🏙 Неон / вапорвейв", 20, 1.5, c3(100, 50, 140), c3(120, 60, 160), c3(140, 50, 180), 40, 900, {0.45, c3(255, 90, 210), c3(80, 200, 255), 0.7, 2}, {c3(255, 170, 255), 0.4, 0.2, 0}, {1.6, 34, 0.7}, 0.15, 1500, 18, 8, {c3(120, 240, 255), true, 5, 0.3}),
		P("🌅 Закат", 17.9, 2, c3(120, 90, 100), c3(150, 110, 120), c3(255, 160, 90), 100, 2500, {0.35, c3(255, 170, 100), c3(200, 110, 80), 0.8, 1.5}, {c3(255, 225, 200), 0.15, 0.1, 0}, {0.5, 24, 1}, 0.2, 0, 12, 14, nil),
		P("🌸 Сакура", 14, 2.6, c3(180, 160, 175), c3(200, 180, 195), c3(255, 220, 235), 300, 3000, {0.3, c3(255, 200, 225), c3(220, 170, 200), 0.2, 1}, {c3(255, 228, 238), 0.25, 0.05, 0.02}, {0.4, 20, 1}, 0.1, 0, 11, 21, {c3(255, 170, 205), false, 3, 0.45}),
		P("☀ Ясный день", 12, 3, c3(140, 140, 140), c3(160, 170, 190), c3(190, 210, 240), 400, 6000, {0.25, c3(190, 210, 240), c3(150, 170, 200), 0.1, 0.4}, {c3(255, 255, 255), 0.05, 0.05, 0}, {0.2, 20, 1.5}, 0.08, 0, 11, 21, nil),
		P("🌫 Туман-ужастик", 2, 0.8, c3(55, 60, 70), c3(65, 70, 80), c3(80, 86, 95), 0, 130, {0.55, c3(150, 155, 165), c3(90, 95, 105), 0, 3}, {c3(215, 225, 230), -0.2, 0.3, -0.05}, {0.3, 20, 1.2}, 0, 800, 20, 8, {c3(200, 205, 210), false, 1, 0.5}),
		P("⬛ Чёрно-белое кино", 15, 2.5, c3(130, 130, 130), c3(150, 150, 150), c3(180, 180, 180), 300, 4000, {0.3, c3(180, 180, 180), c3(120, 120, 120), 0.1, 1}, {c3(255, 255, 255), -1, 0.3, 0}, {0.3, 20, 1.2}, 0.1, 0, 11, 21, nil),
	}
	local function sync()
		local sl = WD.sl
		if not sl.clock then return end
		sl.clock.Set(Lighting.ClockTime)
		sl.bright.Set(Lighting.Brightness)
		local at = Lighting:FindFirstChild("FembiixAtmo")
		sl.atmo.Set(at and at.Density or 0.3)
		sl.fog.Set(Lighting.FogEnd)
		local cc = Lighting:FindFirstChild("FembiixCC")
		sl.sat.Set(cc and cc.Saturation or 0)
		sl.con.Set(cc and cc.Contrast or 0)
		local bl = Lighting:FindFirstChild("FembiixBloom")
		sl.bloom.Set(bl and bl.Intensity or 0)
	end
	local function applyPreset(pr)
		touch()
		Lighting.ClockTime, Lighting.Brightness, Lighting.Ambient, Lighting.OutdoorAmbient = pr.clock, pr.bright, pr.amb, pr.out
		Lighting.FogColor, Lighting.FogStart, Lighting.FogEnd = pr.fogC, pr.fogS, pr.fogE
		local sky = ensure("Sky", "FembiixSky")
		sky.StarCount, sky.MoonAngularSize, sky.SunAngularSize, sky.CelestialBodiesShown = pr.stars, pr.moon, pr.sun, true
		local at = ensure("Atmosphere", "FembiixAtmo")
		at.Density, at.Offset, at.Color, at.Decay, at.Glare, at.Haze = pr.at[1], 0.25, pr.at[2], pr.at[3], pr.at[4], pr.at[5]
		local cc = ensure("ColorCorrectionEffect", "FembiixCC")
		cc.TintColor, cc.Saturation, cc.Contrast, cc.Brightness = pr.cc[1], pr.cc[2], pr.cc[3], pr.cc[4]
		local bl = ensure("BloomEffect", "FembiixBloom")
		bl.Intensity, bl.Size, bl.Threshold = pr.bl[1], pr.bl[2], pr.bl[3]
		local sr = ensure("SunRaysEffect", "FembiixRays")
		sr.Intensity, sr.Spread = pr.rays, 0.8
		setParticles(pr.part)
		sync()
		notify(pr.name)
	end

	-- ---------- шляпы (локальные, видишь только ты) ----------
	local function disc(r, h, y, col, mat, x)
		return {Enum.PartType.Cylinder, Vector3.new(h, r * 2, r * 2), CFrame.new(x or 0, y, 0) * CFrame.Angles(0, 0, math.pi / 2), col, mat or Enum.Material.SmoothPlastic}
	end
	local function blk(size, cf, col, mat, shape, spin)
		return {shape or Enum.PartType.Block, size, cf, col, mat or Enum.Material.SmoothPlastic, spin}
	end
	local HATS = {}
	HATS.CHINA = function() -- китайская соломенная шляпа-конус
		local l = {}
		for i = 0, 11 do
			l[#l + 1] = disc(3.5 * (1 - i / 12.5), 0.2, 0.1 + i * 0.17, (i % 2 == 0) and c3(226, 192, 120) or c3(205, 170, 100), Enum.Material.Fabric)
		end
		l[#l + 1] = blk(Vector3.new(0.55, 0.55, 0.55), CFrame.new(0, 2.3, 0), c3(205, 30, 30), nil, Enum.PartType.Ball)
		l[#l + 1] = disc(1.15, 0.14, 0, c3(150, 25, 25))
		return l
	end
	HATS.WITCH = function()
		local l = {disc(2.8, 0.15, 0.05, c3(55, 25, 85)), disc(1.8, 0.25, 0.3, c3(255, 140, 20))}
		for i = 0, 10 do
			l[#l + 1] = disc(1.65 * (1 - i / 11.5), 0.42, 0.5 + i * 0.4, c3(65, 28, 100), nil, i * i * 0.012)
		end
		return l
	end
	HATS.CROWN = function()
		local l = {disc(1.3, 0.55, 0.28, c3(255, 200, 40), Enum.Material.Metal)}
		for i = 0, 7 do
			local a = i / 8 * TAU
			l[#l + 1] = blk(Vector3.new(0.34, 0.95, 0.34), CFrame.new(math.cos(a) * 1.15, 1.0, math.sin(a) * 1.15), c3(255, 210, 60), Enum.Material.Metal)
			l[#l + 1] = blk(Vector3.new(0.3, 0.3, 0.3), CFrame.new(math.cos(a) * 1.15, 1.6, math.sin(a) * 1.15), (i % 2 == 0) and c3(230, 40, 60) or c3(60, 160, 255), Enum.Material.Neon, Enum.PartType.Ball)
		end
		return l
	end
	HATS.HALO = function()
		local l = {}
		for i = 0, 15 do
			local a = i / 16 * TAU
			l[#l + 1] = blk(Vector3.new(0.38, 0.38, 0.38), CFrame.new(math.cos(a) * 1.6, 2.4, math.sin(a) * 1.6), c3(255, 235, 140), Enum.Material.Neon, Enum.PartType.Ball, true)
		end
		return l
	end
	HATS.HORNS = function()
		local l = {}
		for _, side in ipairs({-1, 1}) do
			for i = 0, 4 do
				l[#l + 1] = blk(Vector3.new(0.42 - i * 0.06, 0.6, 0.42 - i * 0.06), CFrame.new(side * (0.7 + i * 0.3), 0.4 + i * 0.5, 0) * CFrame.Angles(0, 0, -side * (0.3 + i * 0.12)), c3(150, 20, 30))
			end
		end
		return l
	end
	HATS.TOP = function()
		return {disc(1.1, 2, 1.0, c3(20, 20, 24)), disc(1.9, 0.15, 0.08, c3(20, 20, 24)), disc(1.12, 0.35, 0.35, c3(200, 30, 50))}
	end
	HATS.PUMPKIN = function()
		return {blk(Vector3.new(2.6, 2.2, 2.6), CFrame.new(0, 1.0, 0), c3(255, 125, 20), nil, Enum.PartType.Ball), blk(Vector3.new(0.35, 0.7, 0.35), CFrame.new(0, 2.2, 0), c3(60, 140, 50))}
	end
	local HAT_LIST = {{"NONE", "🚫 Без шляпы"}, {"CHINA", "🥢 Китайская шляпа"}, {"WITCH", "🧙 Ведьмина"}, {"CROWN", "👑 Корона"},
		{"HALO", "😇 Нимб"}, {"HORNS", "😈 Рога"}, {"TOP", "🎩 Цилиндр"}, {"PUMPKIN", "🎃 Тыква"}}
	local hatBtns = {}
	local function clearHat()
		for _, h in ipairs(WD.hatParts) do h.part:Destroy() end
		WD.hatParts = {}
	end
	local function buildHat(key)
		clearHat()
		WD.hatKey = key
		for k, b in pairs(hatBtns) do setBase(b, (k == key) and C.accentDark or C.el) end
		local f = HATS[key]
		if not f then return end
		local sc = WD.hatScale
		for _, d in ipairs(f()) do
			local part = make("Part", {Name = "FembiixHat", Shape = d[1], Size = d[2] * sc, Color = d[4], Material = d[5], Anchored = true,
				CanCollide = false, CanQuery = false, CanTouch = false, CastShadow = false}, camera)
			local off = d[3]
			table.insert(WD.hatParts, {part = part, off = CFrame.new(off.Position * sc) * (off - off.Position), spin = d[6]})
		end
	end

	-- ---------- интерфейс ----------
	local function head(text)
		make("TextLabel", {Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1, Text = text, Font = Enum.Font.GothamBlack, TextSize = 12,
			TextColor3 = C.accent, TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = nx()}, page)
	end
	local info = card(page, nx())
	cardText(info, "🌍 Мир, небо и камера", 15, C.accent, Enum.Font.GothamBlack, 1)
	cardText(info, "Пресеты неба (Хэллоуинская ночь и другие), тонкая настройка света, FOV, 3-е лицо, зум и шляпы. Всё видишь только ты.", 12, C.dim, Enum.Font.GothamMedium, 2)

	head("НЕБО И АТМОСФЕРА")
	local grid = make("Frame", {Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = nx()}, page)
	make("UIGridLayout", {CellSize = UDim2.new(0.5, -4, 0, 36), CellPadding = UDim2.fromOffset(8, 8), SortOrder = Enum.SortOrder.LayoutOrder}, grid)
	for i, pr in ipairs(PRESETS) do
		local b = button(grid, pr.name, C.el, i, 36)
		b.TextSize = 12
		b.MouseButton1Click:Connect(function() applyPreset(pr) end)
	end
	local resetB = button(page, "⟲ ВЕРНУТЬ РОДНОЕ НЕБО ИГРЫ", C.danger, nx(), 36)
	resetB.MouseButton1Click:Connect(function()
		restore()
		sync()
		notify("⟲ Небо игры возвращено")
	end)
	WD.sl.clock = slider(page, page, "🕒 Время суток", 0, 24, 14, 0.1, nx(), function(v) touch(); Lighting.ClockTime = v end)
	WD.sl.bright = slider(page, page, "💡 Яркость", 0, 6, 2, 0.1, nx(), function(v) touch(); Lighting.Brightness = v end)
	WD.sl.atmo = slider(page, page, "🌫 Плотность атмосферы", 0, 1, 0.3, 0.01, nx(), function(v) touch(); ensure("Atmosphere", "FembiixAtmo").Density = v end)
	WD.sl.fog = slider(page, page, "🌁 Дальность тумана", 20, 6000, 3000, 10, nx(), function(v) touch(); Lighting.FogEnd = v end)
	WD.sl.sat = slider(page, page, "🎨 Насыщенность", -1, 2, 0, 0.05, nx(), function(v) touch(); ensure("ColorCorrectionEffect", "FembiixCC").Saturation = v end)
	WD.sl.con = slider(page, page, "◐ Контраст", -0.5, 1, 0, 0.05, nx(), function(v) touch(); ensure("ColorCorrectionEffect", "FembiixCC").Contrast = v end)
	WD.sl.bloom = slider(page, page, "✨ Свечение (Bloom)", 0, 3, 0, 0.05, nx(), function(v) touch(); ensure("BloomEffect", "FembiixBloom").Intensity = v end)
	slider(page, page, "❄ Плотность частиц погоды", 0, 120, 40, 1, nx(), function(v) WD.partRate = v end)
	toggle(page, "⚡ Молнии (вспышки неба)", false, nx(), function(v)
		WD.lightning = v
		if v then touch() end
	end)
	toggle(page, "🌑 Тени мира", true, nx(), function(v) touch(); Lighting.GlobalShadows = v end)

	head("КАМЕРА")
	local function camSnap()
		if not WD.cam then WD.cam = {mode = player.CameraMode, min = player.CameraMinZoomDistance, max = player.CameraMaxZoomDistance, fov = camera.FieldOfView} end
	end
	toggle(page, "🔭 Свой FOV", false, nx(), function(v)
		camSnap()
		WD.fovOn = v
		if not v then camera.FieldOfView = WD.cam.fov end
	end)
	slider(page, page, "🔭 Угол обзора (FOV)", 30, 120, 70, 1, nx(), function(v) WD.fov = v end)
	WD.sl.zmax = slider(page, page, "↔ Макс. отдаление камеры", 5, 1000, 128, 1, nx(), function(v) camSnap(); player.CameraMaxZoomDistance = v end)
	WD.sl.zmin = slider(page, page, "↔ Мин. отдаление камеры", 0.5, 60, 0.5, 0.5, nx(), function(v) camSnap(); player.CameraMinZoomDistance = v end)
	local tpT, fpT
	tpT = toggle(page, "🧍 Всегда 3-е лицо", false, nx(), function(v)
		camSnap()
		if v then
			fpT.Set(false)
			player.CameraMode = Enum.CameraMode.Classic
			player.CameraMinZoomDistance = math.max(6, WD.sl.zmin.Get())
		else
			player.CameraMinZoomDistance = WD.sl.zmin.Get()
		end
	end)
	fpT = toggle(page, "👁 Всегда 1-е лицо", false, nx(), function(v)
		camSnap()
		if v then
			tpT.Set(false)
			player.CameraMode = Enum.CameraMode.LockFirstPerson
		else
			player.CameraMode = Enum.CameraMode.Classic
		end
	end)

	head("ШЛЯПЫ")
	local hgrid = make("Frame", {Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = nx()}, page)
	make("UIGridLayout", {CellSize = UDim2.new(0.5, -4, 0, 36), CellPadding = UDim2.fromOffset(8, 8), SortOrder = Enum.SortOrder.LayoutOrder}, hgrid)
	for i, h in ipairs(HAT_LIST) do
		local b = button(hgrid, h[2], C.el, i, 36)
		b.TextSize = 12
		hatBtns[h[1]] = b
		b.MouseButton1Click:Connect(function() buildHat(h[1]) end)
	end
	slider(page, page, "📏 Размер шляпы", 0.5, 2.5, 1, 0.05, nx(), function(v)
		WD.hatScale = v
		if WD.hatKey ~= "NONE" then buildHat(WD.hatKey) end
	end)
	buildHat("NONE")
	function API.worldItems()
		local L = {}
		for _, pr in ipairs(PRESETS) do L[#L + 1] = {pr.name, function() applyPreset(pr) end} end
		for _, h in ipairs(HAT_LIST) do L[#L + 1] = {"Шляпа: " .. h[2], function() buildHat(h[1]) end} end
		L[#L + 1] = {"⟲ Вернуть родное небо игры", function() restore(); sync() end}
		return L
	end

	-- ---------- покадровое обновление ----------
	function API.worldStep(dt, now)
		local hrp = getHRP()
		if WD.pPart and hrp and WD.pCfg then
			WD.pPart.CFrame = CFrame.new(hrp.Position + Vector3.new(0, WD.pCfg[2] and -3 or 28, 0))
			WD.emitter.Rate = WD.partRate
		end
		if WD.fovOn then camera.FieldOfView = WD.fov end
		if WD.on and WD.lightning then
			if now > WD.nextBolt then
				WD.nextBolt = now + 4 + math.random() * 9
				WD.flashUntil = now + 0.55
			end
			if now < WD.flashUntil then
				local x = (WD.flashUntil - now) / 0.55
				Lighting.ExposureCompensation = ((WD.snap and WD.snap.ExposureCompensation) or 0) + 2.6 * x * x * ((math.random() < 0.75) and 1 or 0.3)
				WD.flashing = true
			elseif WD.flashing then
				WD.flashing = false
				Lighting.ExposureCompensation = (WD.snap and WD.snap.ExposureCompensation) or 0
			end
		end
		if #WD.hatParts > 0 then
			local ch = player.Character
			local hd = ch and ch:FindFirstChild("Head")
			if hd then
				local base = hd.CFrame * CFrame.new(0, hd.Size.Y / 2, 0)
				local sp = CFrame.Angles(0, now * 2.5, 0)
				local tr = ((camera.CFrame.Position - hd.Position).Magnitude < 2) and 1 or 0 -- в 1-м лице шляпа не мешает
				for _, h in ipairs(WD.hatParts) do
					h.part.CFrame = h.spin and (base * sp * h.off) or (base * h.off)
					h.part.Transparency = tr
				end
			end
		end
	end
	function API.worldClear()
		restore()
		clearHat()
		if WD.cam then
			pcall(function()
				player.CameraMode, player.CameraMinZoomDistance, player.CameraMaxZoomDistance = WD.cam.mode, WD.cam.min, WD.cam.max
				camera.FieldOfView = WD.cam.fov
			end)
		end
	end
end

-- ---------- ВКЛАДКА: ИГРОКИ + ОТБАНАНИТЬ СЕРВЕР ----------
do
	local page = scrollList(pagesHolder, UDim2.fromScale(1, 1))
	page.Name = "players"
	page.Visible = false
	pages.players = page
	local order = 0
	local function nx() order += 1; return order end
	local pinned, esp, spectating, espOn = {}, {}, nil, false

	local info = card(page, nx())
	cardText(info, "👥 Игроки сервера", 15, C.accent, Enum.Font.GothamBlack, 1)
	cardText(info, "ESP с именами и дистанцией, наблюдение, телепорт, закладки и режим «Отбананить весь сервер».", 12, C.dim, Enum.Font.GothamMedium, 2)
	toggle(page, "🔍 ESP: подсветка и ники с расстоянием", false, nx(), function(v) espOn = v end)
	local espRange = slider(page, page, "📏 Дальность ESP", 100, 3000, 1500, 50, nx())
	local function unspectate()
		spectating = nil
		local h = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if h then camera.CameraSubject = h end
	end
	local stopSpec = button(page, "⏹ ВЫЙТИ ИЗ НАБЛЮДЕНИЯ", C.el2, nx(), 34)
	stopSpec.MouseButton1Click:Connect(function() unspectate(); notify("Наблюдение выключено") end)

	-- ---------- 🍌 ОТБАНАНИТЬ ВЕСЬ СЕРВЕР ----------
	local bcard = card(page, nx())
	cardText(bcard, "🍌 Отбананить весь сервер", 15, C.accent, Enum.Font.GothamBlack, 1)
	cardText(bcard, "1) Заспавни FoodBanana. Над ним появится подсказка «Отбананить всех».\n2) Возьми банан на ПКМ и нажми ЛКМ — откуси (пропадёт EdiblePart).\n3) Брось на землю (ПКМ), подними ЛКМ и отпусти.\n4) Банан по 0.2 с телепортируется под ноги каждому игроку по кругу. F — стоп.", 12, C.dim, Enum.Font.GothamMedium, 2)
	ui.bananaStatus = cardText(bcard, "Режим выключен", 12, C.text, Enum.Font.GothamBold, 3)
	local bananaOn = false
	local bananas = {}
	local bDur
	toggle(page, "🍌 Режим: Отбананить весь сервер", false, nx(), function(v)
		bananaOn = v
		if not v then
			for m, st in pairs(bananas) do
				if st.gui then st.gui:Destroy() end
				bananas[m] = nil
			end
			ui.bananaStatus.Text = "Режим выключен"
		end
		notify(v and "🍌 Режим бананов включён" or "🍌 Режим бананов выключен")
	end)
	bDur = slider(page, page, "⏱ Время на каждого игрока (сек)", 0.1, 1, 0.2, 0.05, nx())
	local startB = button(page, "▶ ЗАПУСТИТЬ БАНАН СЕЙЧАС (без ритуала)", C.accentDark, nx(), 36)
	local stopB = button(page, "⏹ СТОП  (F)", C.danger, nx(), 34)

	local scanT = 0
	local function countEdible(m)
		local n = 0
		for _, d in ipairs(m:GetDescendants()) do
			if d.Name == "EdiblePart" then n += 1 end
		end
		return n
	end
	local function setTip(st, text)
		if st.lbl.Text ~= text then st.lbl.Text = text end
	end
	local function addBanana(model)
		local part = resolvePart(model)
		if not part then return end
		local ed = countEdible(model)
		local gui = make("BillboardGui", {Name = "FembiixBananaTip", Adornee = part, Size = UDim2.fromOffset(280, 64), StudsOffset = Vector3.new(0, 3.4, 0),
			AlwaysOnTop = true, LightInfluence = 0, ResetOnSpawn = false}, screenGui)
		local f = make("Frame", {Size = UDim2.fromScale(1, 1), BackgroundColor3 = C.panel, BorderSizePixel = 0}, gui)
		round(f, 12)
		stroke(f, C.accent, 2, 0)
		local lbl = make("TextLabel", {Size = UDim2.new(1, -12, 1, -8), Position = UDim2.new(0, 6, 0, 4), BackgroundTransparency = 1, Text = "", TextWrapped = true,
			Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = C.text}, f)
		bananas[model] = {model = model, part = part, maxEd = ed, stage = (ed == 0) and "eaten" or "ready", rests = 0, moving = false, restT = 0, idx = 1, tT = 0, gui = gui, lbl = lbl}
		notify("🍌 Нашёл банан — смотри подсказку над ним")
	end
	local function targets()
		local list = {}
		for _, pl in ipairs(Players:GetPlayers()) do
			if pl ~= player then
				local ch = pl.Character
				local h = ch and ch:FindFirstChild("HumanoidRootPart")
				local hum = ch and ch:FindFirstChildOfClass("Humanoid")
				if h and hum and hum.Health > 0 then list[#list + 1] = h end
			end
		end
		return list
	end
	local function activate(st)
		st.stage, st.idx, st.tT = "active", 1, 0
		pcall(function() sethiddenproperty(player, "SimulationRadius", 1e9) end)
		notify("🍌 ОТБАНАНИВАЕМ ВЕСЬ СЕРВЕР! F — стоп")
	end
	function API.bananaStop()
		local any = false
		for _, st in pairs(bananas) do
			if st.stage == "active" then
				st.stage, st.rests, st.moving = "eaten", 0, false
				any = true
			end
		end
		if any then notify("🍌 Остановлено") end
	end
	function API.bananaRunning()
		for _, st in pairs(bananas) do
			if st.stage == "active" then return true end
		end
		return false
	end
	startB.MouseButton1Click:Connect(function()
		if not bananaOn then notify("Сначала включи режим бананов", C.danger) return end
		for _, st in pairs(bananas) do
			if st.stage ~= "active" then activate(st) return end
		end
		notify("Банан не найден в твоих игрушках", C.danger)
	end)
	stopB.MouseButton1Click:Connect(function() API.bananaStop() end)
	ui.bananaStopBtn = make("TextButton", {Size = UDim2.fromOffset(84, 84), AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -24, 1, -300),
		BackgroundColor3 = C.danger, Text = "🍌⏹", TextSize = 28, AutoButtonColor = false, Visible = false, BorderSizePixel = 0}, screenGui)
	round(ui.bananaStopBtn, 42)
	ui.bananaStopBtn.Activated:Connect(function() API.bananaStop() end)

	local function bananaStep(dt)
		if not bananaOn then return end
		scanT -= dt
		if scanT <= 0 then
			scanT = 0.5
			local folder = getFolder()
			if folder then
				for _, ch in ipairs(folder:GetChildren()) do
					if ch.Name == "FoodBanana" and not bananas[ch] then addBanana(ch) end
				end
			end
		end
		local n, nActive = 0, 0
		for model, st in pairs(bananas) do
			n += 1
			if not model.Parent or not st.part.Parent then
				st.gui:Destroy()
				bananas[model] = nil
			elseif st.stage == "ready" then
				setTip(st, "🍌 Отбананить всех!\nВозьми на ПКМ и жми ЛКМ — откуси")
				st.chkT = (st.chkT or 0) - dt
				if st.chkT <= 0 then
					st.chkT = 0.15
					local ed = countEdible(model)
					if ed > st.maxEd then st.maxEd = ed end
					if ed < st.maxEd or ed == 0 then
						st.stage, st.rests, st.moving, st.restT = "eaten", 0, false, 0
						notify("🍌 Откусил! Брось на землю (ПКМ), подними ЛКМ и отпусти")
					end
				end
			elseif st.stage == "eaten" then
				setTip(st, "🍌 Брось на землю (ПКМ), подними ЛКМ и отпусти\n(" .. st.rests .. " из 2)")
				local sp = st.part.AssemblyLinearVelocity.Magnitude
				if sp > 6 then
					st.moving, st.restT = true, 0
				elseif st.moving then
					st.restT += dt
					if st.restT > 0.45 then
						st.moving, st.restT = false, 0
						st.rests += 1
						if st.rests >= 2 then activate(st) end
					end
				end
			else
				nActive += 1
				local list = targets()
				if #list == 0 then
					setTip(st, "🍌 Других игроков нет\nF — стоп")
				else
					st.tT += dt
					if st.tT >= bDur.Get() then
						st.tT = 0
						st.idx = st.idx % #list + 1
					end
					if st.idx > #list then st.idx = 1 end
					local th = list[st.idx]
					local feet = th.Position - Vector3.new(0, 2.8, 0) + th.CFrame.LookVector * 0.4
					moveObj(model, st.part, CFrame.new(feet) * CFrame.Angles(0, math.random() * 6.28, 0)) -- тпхаем банан под ноги
					st.part.AssemblyLinearVelocity = Vector3.new(0, -12, 0)
					st.part.AssemblyAngularVelocity = Vector3.zero
					local pl = Players:GetPlayerFromCharacter(th.Parent)
					setTip(st, "🍌 ОТБАНАНИВАЮ: " .. (pl and pl.DisplayName or "?") .. " (" .. st.idx .. "/" .. #list .. ")\nF — стоп")
				end
			end
		end
		ui.bananaStatus.Text = ("Бананов найдено: %d · активных: %d"):format(n, nActive)
		ui.bananaStopBtn.Visible = touchUiOn and nActive > 0
	end
	connect(RunService.Heartbeat, function(dt) API.safe("банан", bananaStep, dt) end)

	-- ---------- список игроков и ESP ----------
	local listHolder = make("Frame", {Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = 900}, page)
	make("UIListLayout", {Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder}, listHolder)
	local function espClear(pl)
		local e = esp[pl]
		if e then
			pcall(function() e.hl:Destroy() end)
			pcall(function() e.bb:Destroy() end)
			esp[pl] = nil
		end
	end
	local function spectate(pl)
		local hum = pl.Character and pl.Character:FindFirstChildOfClass("Humanoid")
		if not hum then notify("У игрока нет персонажа", C.danger) return end
		spectating = pl
		camera.CameraSubject = hum
		notify("👁 Наблюдаю: " .. pl.DisplayName)
	end
	local function teleport(pl)
		local th = pl.Character and pl.Character:FindFirstChild("HumanoidRootPart")
		local me = getHRP()
		if th and me then
			me.CFrame = th.CFrame * CFrame.new(0, 2, 5)
			notify("📍 Телепорт к " .. pl.DisplayName)
		end
	end
	local function rebuild()
		for _, ch in ipairs(listHolder:GetChildren()) do
			if ch:IsA("Frame") then ch:Destroy() end
		end
		local me = getHRP()
		local list = Players:GetPlayers()
		table.sort(list, function(a, b) return a.DisplayName:lower() < b.DisplayName:lower() end)
		local idx = 0
		for _, pl in ipairs(list) do
			if pl ~= player then
				idx += 1
				local th = pl.Character and pl.Character:FindFirstChild("HumanoidRootPart")
				local dist = (th and me) and math.floor((th.Position - me.Position).Magnitude) or -1
				local row = make("Frame", {Size = UDim2.new(1, 0, 0, 46), BackgroundColor3 = C.panel, BorderSizePixel = 0, LayoutOrder = idx}, listHolder)
				round(row, 12)
				stroke(row, Color3.fromRGB(226, 230, 244), 1, 0)
				make("TextLabel", {Size = UDim2.new(1, -150, 0, 22), Position = UDim2.new(0, 12, 0, 4), BackgroundTransparency = 1, Text = pl.DisplayName,
					Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = C.text, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd}, row)
				make("TextLabel", {Size = UDim2.new(1, -150, 0, 16), Position = UDim2.new(0, 12, 0, 25), BackgroundTransparency = 1,
					Text = "@" .. pl.Name .. ((dist >= 0) and ("  ·  " .. dist .. " ст.") or ""), Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = C.dim,
					TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd}, row)
				local function ib(txt, x, col, fn)
					local b = make("TextButton", {Size = UDim2.fromOffset(34, 30), AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, x, 0.5, 0), BackgroundColor3 = col,
						Text = txt, TextSize = 15, AutoButtonColor = false, BorderSizePixel = 0}, row)
					round(b, 9)
					b:SetAttribute("Base", col)
					attachHover(b)
					b.MouseButton1Click:Connect(fn)
				end
				ib("👁", -92, C.el, function() spectate(pl) end)
				ib("📍", -52, C.el, function() teleport(pl) end)
				ib(pinned[pl] and "⭐" or "☆", -12, pinned[pl] and C.gold or C.el, function()
					pinned[pl] = not pinned[pl] or nil
					rebuild()
				end)
			end
		end
	end
	local function espTick()
		local me = getHRP()
		local range = espRange.Get()
		for _, pl in ipairs(Players:GetPlayers()) do
			if pl ~= player then
				local ch = pl.Character
				local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
				local dist = (hrp and me) and (hrp.Position - me.Position).Magnitude or 0
				local show = hrp ~= nil and ((espOn and dist <= range) or pinned[pl])
				local e = esp[pl]
				if show then
					if e and e.ch ~= ch then espClear(pl); e = nil end
					if not e then
						local hl = make("Highlight", {Name = "FembiixESP", Adornee = ch, FillTransparency = 1, OutlineTransparency = 0, DepthMode = Enum.HighlightDepthMode.AlwaysOnTop}, camera)
						local bb = make("BillboardGui", {Name = "FembiixTag", Size = UDim2.fromOffset(180, 34), StudsOffset = Vector3.new(0, 3.8, 0), AlwaysOnTop = true, LightInfluence = 0}, hrp)
						local lb = make("TextLabel", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 14,
							TextColor3 = Color3.new(1, 1, 1), TextStrokeTransparency = 0.3}, bb)
						e = {hl = hl, bb = bb, lb = lb, ch = ch}
						esp[pl] = e
					end
					e.hl.OutlineColor = pinned[pl] and C.gold or C.accent
					e.lb.Text = pl.DisplayName .. "  ·  " .. math.floor(dist) .. " ст."
				elseif e then
					espClear(pl)
				end
			end
		end
		for pl in pairs(esp) do
			if not pl.Parent then espClear(pl) end
		end
	end
	local espT, listT = 0, 99
	function API.playersStep(dt)
		espT -= dt
		listT += dt
		if espT <= 0 then
			espT = 0.25
			espTick()
		end
		if listT > 3 and page.Visible then
			listT = 0
			rebuild()
		end
		if spectating and (not spectating.Parent or not spectating.Character) then unspectate() end
	end
	function API.playersClear()
		espOn = false
		for pl in pairs(esp) do espClear(pl) end
		unspectate()
		bananaOn = false
		for m, st in pairs(bananas) do
			if st.gui then st.gui:Destroy() end
			bananas[m] = nil
		end
	end
end

-- ---------- ВКЛАДКА: НАСТРОЙКИ ----------
local fakeBoxPart, fullBodyBox
local playIntro
do
	local page = scrollList(pagesHolder, UDim2.new(1, 0, 1, 0))
	page.Name = "settings"
	page.Visible = false
	pages.settings = page

	slider(page, page, "Масштаб интерфейса", 0.6, 1.4, API.cfg.userMul or 1, 0.05, 1, function(v) userMul = v; userScale = autoScale() * v; uiScale.Scale = userScale; API.cfg.userMul = v; API.save() end)
	slider(page, page, "Дальность захвата", 10, 150, 30, 1, 2, function(v) captureRange = v end)
	toggle(page, "Прицел на экране", true, 3, function(v) showCrosshair = v; ui.cross.Visible = v end)
	toggle(page, "Красная рамка вокруг тела", true, 4, function(v) showBodyBox = v end)
	toggle(page, "Экранные кнопки (для сенсора)", touchUiOn, 5, function(v) touchUiOn = v; API.cfg.touchUi = v; API.save() end)
	toggle(page, "◧ Компактная панель (только иконки)", UIK.compact == true, 5, function(v) UIK.setCompact(v) end)
	do
		local row = make("Frame", {Size = UDim2.new(1, 0, 0, 40 + UIK.thv), BackgroundColor3 = C.panel, BorderSizePixel = 0, LayoutOrder = 5}, page)
		round(row, 12)
		stroke(row, Color3.fromRGB(226, 230, 244), 1, 0)
		make("TextLabel", {Size = UDim2.new(0.3, 0, 1, 0), Position = UDim2.new(0, 12, 0, 0), BackgroundTransparency = 1, Text = "🎬 Интро", TextColor3 = C.text,
			Font = Enum.Font.GothamMedium, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left}, row)
		local btns = {}
		local function paintIntro()
			for k, b in pairs(btns) do setBase(b, ((API.cfg.introMode or "full") == k) and C.accentDark or C.el) end
		end
		for i, o in ipairs({{"full", "Полное"}, {"short", "Быстрое"}, {"off", "Выкл"}}) do
			local b = make("TextButton", {Size = UDim2.new(0.21, 0, 0, 26), Position = UDim2.new(0.31 + (i - 1) * 0.23, 0, 0.5, -13), Text = o[2], Font = Enum.Font.GothamBold,
				TextSize = 12, BorderSizePixel = 0, AutoButtonColor = false, BackgroundColor3 = C.el, TextColor3 = C.text}, row)
			round(b, 8)
			b:SetAttribute("Base", C.el)
			attachHover(b)
			btns[o[1]] = b
			b.MouseButton1Click:Connect(function() API.cfg.introMode = o[1]; API.save(); paintIntro() end)
		end
		paintIntro()
	end

	local info = card(page, 6)
	cardText(info, "ℹ Подсказки", 14, C.accent, Enum.Font.GothamBlack, 1)
	cardText(info, "• RightShift: скрыть/показать окно\n• Ракета: подойди, потом кликни по ней\n• Вкладка «Моя ракета» включает питомца, F — действие режима\n• Камера: ЛКМ/ПКМ или палец вне окна\n• Спаркеры берутся так же, как ракета\n• Дальность захвата общая для всего", 12, C.dim, Enum.Font.GothamMedium, 2)

	local introBtn = button(page, "▶ ПОКАЗАТЬ ИНТРО", C.el2, 7, 34)
	introBtn.MouseButton1Click:Connect(function() if not introActive then playIntro(function() setHidden(false) end) end end)

	local unloadBtn = button(page, "☠ ВЫГРУЗИТЬ СКРИПТ", C.danger, 8, 36)
	unloadBtn.MouseButton1Click:Connect(function()
		if activeRocket then cancelRocket() end
		releaseAllSparklers()
		API.releaseAllSwarm()
		API.camRelease()
		pcall(API.laserClear)
		pcall(API.worldClear)
		pcall(API.playersClear)
		pcall(function() ui.bark:Destroy() end)
		pcall(function() RunService:UnbindFromRenderStep("FembiixMain") end)
		for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end
		pcall(function() fakeBoxPart:Destroy() end)
		pcall(function() fullBodyBox:Destroy() end)
		pcall(function() bhCore:Destroy() end)
		pcall(function() bhGlow:Destroy() end)
		pcall(function() aimCore:Destroy() end)
		for _, e in ipairs(wire.pool) do pcall(function() e.part:Destroy() end) end
		screenGui:Destroy()
	end)
end

-- рамка вокруг тела
fakeBoxPart = make("Part", {Name = "FembiixBoxPart", Size = Vector3.new(3, 5, 3), Transparency = 1, CanCollide = false, Anchored = true, CanQuery = false, CanTouch = false}, workspace)
fullBodyBox = make("SelectionBox", {Name = "FembiixBox", Color3 = Color3.fromRGB(255, 40, 20), LineThickness = 0.08, Adornee = fakeBoxPart})
pcall(function() fullBodyBox.Parent = CoreGui end)
if not fullBodyBox.Parent then fullBodyBox.Parent = screenGui end

-- ======================= ПОИСК-ПАЛИТРА (Ctrl+K), ПАНИКА, ПОМОЩЬ =======================
do
	function API.panic() -- всё остановить и вернуть как было
		pcall(API.dismount)
		pcall(API.bobikCancel)
		pcall(API.setSwarmLaunched, false)
		pcall(API.releaseAllSwarm)
		pcall(releaseAllSparklers)
		pcall(API.bananaStop)
		pcall(API.camRelease)
		if activeRocket then pcall(cancelRocket) end
		notify("⛔ ПАНИКА: всё остановлено", C.danger)
	end

	local pal = make("Frame", {Name = "Palette", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(20, 24, 44), BackgroundTransparency = 0.55,
		Visible = false, ZIndex = 150, BorderSizePixel = 0}, screenGui)
	local back = make("TextButton", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", AutoButtonColor = false}, pal)
	local box = make("Frame", {AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 70), Size = UDim2.fromOffset(500, 380), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Active = true}, pal)
	round(box, 16)
	stroke(box, Color3.fromRGB(208, 215, 240), 1.5, 0)
	make("UIScale", {Scale = math.clamp(camera.ViewportSize.X / 580, 0.6, 1)}, box)
	local tb = make("TextBox", {Size = UDim2.new(1, -24, 0, 42), Position = UDim2.new(0, 12, 0, 12), BackgroundColor3 = C.el, Text = "", TextColor3 = C.text,
		PlaceholderText = "🔍 Режим, небо, шляпа, действие…   Enter — выбрать · Esc — закрыть", PlaceholderColor3 = C.dim, Font = Enum.Font.GothamMedium, TextSize = 14,
		ClearTextOnFocus = false, TextXAlignment = Enum.TextXAlignment.Left, BorderSizePixel = 0}, box)
	round(tb, 12)
	make("UIPadding", {PaddingLeft = UDim.new(0, 14)}, tb)
	local res = make("ScrollingFrame", {Size = UDim2.new(1, -16, 1, -70), Position = UDim2.new(0, 8, 0, 62), BackgroundTransparency = 1, BorderSizePixel = 0,
		ScrollBarThickness = 4, ScrollBarImageColor3 = C.accent, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y}, box)
	make("UIListLayout", {Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.LayoutOrder}, res)

	local items, shown, rows, sel = {}, {}, {}, 1
	local function buildItems()
		local L = {}
		local function add(label, kw, fn, sub) L[#L + 1] = {label = label, kw = ulower(label .. " " .. kw), fn = fn, sub = sub} end
		for _, t in ipairs(TABS) do add(t[2] .. " Вкладка: " .. t[3], "вкладка tab открыть", function() selectTab(t[1]) end) end
		for _, m in ipairs(ROCKET_MODES) do add("🕹 " .. m.label, "ручная ракета полёт " .. m.key, function() selectTab("rockets"); ui.selectRocketMode(m.key) end, m.desc) end
		for _, m in ipairs(SWARM_MODES) do add("🐕 " .. m.label, "моя ракета питомец " .. m.key, function() selectTab("swarm"); ui.selectSwarmMode(m.key) end, m.desc) end
		for _, m in ipairs(SPARK_MODES) do add("🎆 " .. m.label, "спаркеры огни " .. m.key, function() selectTab("sparklers"); ui.selectSparkMode(m.key) end, m.desc) end
		if API.worldItems then
			for _, it in ipairs(API.worldItems()) do add("🌍 " .. it[1], "мир небо шляпа камера", function() selectTab("world"); it[2]() end) end
		end
		add("⛔ Паника: всё выключить", "стоп остановить панику end", API.panic)
		add("◧ Компактная панель вкл/выкл", "компакт иконки панель", function() UIK.setCompact(not UIK.compact) end)
		add("⌨ Горячие клавиши", "помощь клавиши help", function() UIK.showHelp() end)
		add("⌖ Центрировать окно", "окно центр позиция", function() MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0) end)
		add("🙈 Скрыть окно", "скрыть спрятать rightshift", function() setHidden(true) end)
		add("▶ Показать интро", "интро заставка", function() playIntro(function() setHidden(false); UIK.entrance() end) end)
		return L
	end
	local function paint()
		for i, r in ipairs(rows) do
			r.BackgroundTransparency = (i == sel) and 0.85 or 1
			r.BackgroundColor3 = C.accent
		end
		if rows[sel] then res.CanvasPosition = Vector2.new(0, math.max(0, (sel - 4) * 34)) end
	end
	local function close() pal.Visible = false; tb:ReleaseFocus() end
	local function run(i)
		local it = shown[i]
		if not it then return end
		close()
		local ok, err = pcall(it.fn)
		if not ok then warn("[Fembiix] палитра: " .. tostring(err)) end
	end
	local function refresh()
		for _, r in ipairs(rows) do r:Destroy() end
		rows, shown = {}, {}
		local toks = {}
		for w in ulower(tb.Text):gmatch("%S+") do toks[#toks + 1] = w end
		for _, it in ipairs(items) do
			local ok = true
			for _, w in ipairs(toks) do
				if not it.kw:find(w, 1, true) then ok = false break end
			end
			if ok then shown[#shown + 1] = it end
			if #shown >= 40 then break end
		end
		sel = 1
		for i, it in ipairs(shown) do
			local b = make("TextButton", {Size = UDim2.new(1, 0, 0, it.sub and 42 or 32), BackgroundColor3 = C.accent, BackgroundTransparency = 1, AutoButtonColor = false, Text = "",
				BorderSizePixel = 0, LayoutOrder = i}, res)
			round(b, 9)
			make("TextLabel", {Size = UDim2.new(1, -16, 0, 22), Position = UDim2.new(0, 10, 0, it.sub and 3 or 5), BackgroundTransparency = 1, Text = it.label, Font = Enum.Font.GothamBold,
				TextSize = 13, TextColor3 = C.text, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd}, b)
			if it.sub then
				make("TextLabel", {Size = UDim2.new(1, -16, 0, 14), Position = UDim2.new(0, 10, 0, 24), BackgroundTransparency = 1, Text = it.sub, Font = Enum.Font.Gotham, TextSize = 10,
					TextColor3 = C.dim, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd}, b)
			end
			b.MouseEnter:Connect(function() sel = i; paint() end)
			b.MouseButton1Click:Connect(function() run(i) end)
			rows[i] = b
		end
		paint()
	end
	function UIK.openPalette()
		items = buildItems()
		pal.Visible = true
		tb.Text = ""
		refresh()
		box.Position = UDim2.new(0.5, 0, 0, 40)
		tween(box, {Position = UDim2.new(0.5, 0, 0, 70)}, 0.25, Enum.EasingStyle.Back)
		task.defer(function() tb:CaptureFocus(); tb.Text = "" end)
	end
	tb:GetPropertyChangedSignal("Text"):Connect(refresh)
	back.MouseButton1Click:Connect(close)
	connect(UserInputService.InputBegan, function(input)
		if not pal.Visible then return end
		if input.KeyCode == Enum.KeyCode.Down then sel = math.min(sel + 1, #shown); paint()
		elseif input.KeyCode == Enum.KeyCode.Up then sel = math.max(sel - 1, 1); paint()
		elseif input.KeyCode == Enum.KeyCode.Return then run(sel)
		elseif input.KeyCode == Enum.KeyCode.Escape then close() end
	end)

	-- окно «Горячие клавиши»
	local help = make("TextButton", {Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(20, 24, 44), BackgroundTransparency = 0.55, Text = "", AutoButtonColor = false,
		Visible = false, ZIndex = 160, BorderSizePixel = 0}, screenGui)
	local hb2 = make("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(440, 330), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0}, help)
	round(hb2, 16)
	stroke(hb2, Color3.fromRGB(208, 215, 240), 1.5, 0)
	make("UIScale", {Scale = math.clamp(camera.ViewportSize.X / 520, 0.6, 1)}, hb2)
	make("TextLabel", {Size = UDim2.new(1, -32, 0, 30), Position = UDim2.new(0, 16, 0, 12), BackgroundTransparency = 1, Text = "⌨ Горячие клавиши", Font = Enum.Font.GothamBlack, TextSize = 18,
		TextColor3 = C.accent, TextXAlignment = Enum.TextXAlignment.Left}, hb2)
	make("TextLabel", {Size = UDim2.new(1, -32, 1, -60), Position = UDim2.new(0, 16, 0, 48), BackgroundTransparency = 1, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top, Font = Enum.Font.GothamMedium, TextSize = 13, TextColor3 = C.text,
		Text = "RightShift / H — скрыть и показать окно\nCtrl+K или / — поиск по всему\n[  и  ] — предыдущая / следующая вкладка\nEnd — ПАНИКА: всё выключить\nF — действие питомца (залп, сесть, Бобик, огонь дракона)\nF — стоп бананов\nG — ехать к точке прицела при катании\nX — отмена Бобика\nПКМ/ЛКМ по земле — ехать туда при катании\n\nЗвёздочка ☆ у режима — в избранное, оно поднимается наверх.\nКнопка ◧ — компактная панель. Нажми, чтобы закрыть."}, hb2)
	function UIK.showHelp() help.Visible = true end
	help.MouseButton1Click:Connect(function() help.Visible = false end)
end

ui.selectRocketMode("MANUAL")
ui.selectSwarmMode("FOLLOW")
ui.selectSparkMode("HEART")
selectTab((pages[API.cfg.lastTab or ""] and API.cfg.lastTab ~= "swarm") and API.cfg.lastTab or "rockets", true)

-- ============================ ИНТРО 2.0 ============================
function UIK.entrance() -- вкладки по очереди въезжают слева
	for i, tb in ipairs(TABS) do
		local t = tabBtns[tb[1]]
		t.btn.Position = UDim2.new(0, -220, 0, t.y)
		task.delay(0.06 * i, function() tween(t.btn, {Position = UDim2.new(0, 10, 0, t.y)}, 0.45, Enum.EasingStyle.Back) end)
	end
end

playIntro = function(onDone)
	introActive = true
	MainFrame.Visible = false
	bubble.Visible = false
	local K = (API.cfg.introMode == "short") and 0.45 or 1
	local skipped, finished = false, false
	local iconns = {}
	local vp = camera.ViewportSize
	local ov = make("CanvasGroup", {Name = "Intro", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(246, 248, 255), BorderSizePixel = 0, ZIndex = 100, Active = true}, screenGui)
	make("UIGradient", {Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(218, 226, 255)), Rotation = 60}, ov)

	-- бегущая сетка
	local gx, gy = math.ceil(vp.X / 48) + 3, math.ceil(vp.Y / 48) + 3
	local gridC = make("Frame", {Size = UDim2.fromOffset(gx * 48, gy * 48), BackgroundTransparency = 1}, ov)
	for i = 0, gy do
		make("Frame", {Size = UDim2.new(1, 0, 0, 1), Position = UDim2.fromOffset(0, i * 48), BackgroundColor3 = Color3.fromRGB(180, 192, 235), BackgroundTransparency = 0.72, BorderSizePixel = 0}, gridC)
	end
	for i = 0, gx do
		make("Frame", {Size = UDim2.new(0, 1, 1, 0), Position = UDim2.fromOffset(i * 48, 0), BackgroundColor3 = Color3.fromRGB(180, 192, 235), BackgroundTransparency = 0.72, BorderSizePixel = 0}, gridC)
	end
	tween(gridC, {Position = UDim2.fromOffset(-48, -48)}, 2.4, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1)
	-- цветные пятна и лучи света
	for i, b in ipairs({{0.2, 0.25, Color3.fromRGB(150, 170, 255)}, {0.82, 0.74, Color3.fromRGB(255, 170, 215)}, {0.8, 0.2, Color3.fromRGB(160, 235, 255)}}) do
		local f = make("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(b[1], b[2]), Size = UDim2.fromOffset(380, 380), BackgroundColor3 = b[3], BackgroundTransparency = 0.7, BorderSizePixel = 0}, ov)
		round(f, 400)
		tween(f, {Position = UDim2.fromScale(b[1] + ((i % 2 == 0) and 0.06 or -0.06), b[2] + 0.05), Size = UDim2.fromOffset(450, 450)}, 3 + i, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
	end
	for i = 1, 2 do
		local bm = make("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(-0.3, 0.5), Size = UDim2.new(0, 110, 1.7, 0), Rotation = 22,
			BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0.8, BorderSizePixel = 0, ZIndex = 2}, ov)
		tween(bm, {Position = UDim2.fromScale(1.3, 0.5)}, 2.6 + i * 0.9, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1)
	end

	local stack = make("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(), BackgroundTransparency = 1, ZIndex = 5}, ov)
	make("UIScale", {Scale = math.clamp(math.min(vp.Y / 650, vp.X / 540), 0.5, 1.25)}, stack)

	-- орбитальные точки вокруг логотипа (считаем покадрово)
	local dots = {}
	for i = 1, 22 do
		dots[i] = make("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(8, 8), BackgroundColor3 = Color3.fromHSV((0.55 + i / 22 * 0.4) % 1, 0.55, 1),
			BackgroundTransparency = 1, BorderSizePixel = 0}, stack)
		round(dots[i], 8)
	end
	local t0 = os.clock()
	table.insert(iconns, RunService.RenderStepped:Connect(function()
		local t = os.clock() - t0
		local fade = math.clamp((t - 0.6 * K) / 0.8, 0, 1)
		for i, d in ipairs(dots) do
			local a = t * (0.9 + (i % 3) * 0.25) + i * TAU / 22
			local r = 86 + 12 * math.sin(t * 2 + i)
			d.Position = UDim2.fromOffset(math.cos(a) * r, -130 + math.sin(a) * r * 0.55)
			d.BackgroundTransparency = 1 - 0.8 * fade
			local s = 5 + 4 * (0.5 + 0.5 * math.sin(a * 2))
			d.Size = UDim2.fromOffset(s, s)
		end
	end))

	-- логотип с вращающимся кольцом
	local ring = make("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(0, -130), Size = UDim2.fromOffset(0, 0), BackgroundTransparency = 1}, stack)
	round(ring, 200)
	local rs = stroke(ring, Color3.new(1, 1, 1), 4, 0)
	local rg = make("UIGradient", {Color = ColorSequence.new({ColorSequenceKeypoint.new(0, C.accent), ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 120, 200)), ColorSequenceKeypoint.new(1, C.accent)})}, rs)
	tween(rg, {Rotation = 360}, 2.2, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1)
	local logo = make("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(0, -130), Size = UDim2.fromOffset(0, 0), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0}, stack)
	round(logo, 28)
	local lgr = make("UIGradient", {Color = ColorSequence.new(C.accent, Color3.fromRGB(190, 100, 255)), Rotation = 45}, logo)
	tween(lgr, {Rotation = 405}, 4, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1)
	local fl = make("TextLabel", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "F", Font = Enum.Font.GothamBlack, TextSize = 1, TextColor3 = Color3.new(1, 1, 1)}, logo)

	-- буквы FEMBIIX прилетают со всех сторон, потом по ним проходит блик
	local row = make("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(0, -18), Size = UDim2.new(0, 0, 0, 80), AutomaticSize = Enum.AutomaticSize.X, BackgroundTransparency = 1}, stack)
	make("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center, Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder}, row)
	local letters, shines = {}, {}
	for i, ch in ipairs({"F", "E", "M", "B", "I", "I", "X"}) do
		local cell = make("Frame", {Size = UDim2.fromOffset(ch == "I" and 26 or 52, 80), BackgroundTransparency = 1, LayoutOrder = i}, row)
		local base = (i >= 5) and C.accent or C.text
		letters[i] = make("TextLabel", {Size = UDim2.fromScale(1, 1), Position = UDim2.fromOffset(math.random(-520, 520), math.random(-420, -120)), Rotation = math.random(-200, 200),
			BackgroundTransparency = 1, Text = ch, Font = Enum.Font.GothamBlack, TextSize = 66, TextColor3 = Color3.new(1, 1, 1), TextTransparency = 1}, cell)
		shines[i] = make("UIGradient", {Color = ColorSequence.new({ColorSequenceKeypoint.new(0, base), ColorSequenceKeypoint.new(0.42, base),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 190, 240)), ColorSequenceKeypoint.new(0.58, base), ColorSequenceKeypoint.new(1, base)}), Offset = Vector2.new(-1.2, 0)}, letters[i])
	end
	local sub = make("TextLabel", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(0, 42), Size = UDim2.fromOffset(520, 18), BackgroundTransparency = 1,
		Text = "A D M I N   ·   W H I T E   E D I T I O N   ·   v 5", Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = C.dim, TextTransparency = 1}, stack)

	-- приветствие с твоим аватаром
	local hour = tonumber(os.date("%H")) or 12
	local greet = (hour < 5 and "Доброй ночи") or (hour < 12 and "Доброе утро") or (hour < 18 and "Добрый день") or "Добрый вечер"
	local av = make("ImageLabel", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(-132, 80), Size = UDim2.fromOffset(0, 0), BackgroundColor3 = C.el, BorderSizePixel = 0, ImageTransparency = 1}, stack)
	round(av, 20)
	local gl = make("TextLabel", {AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromOffset(-104, 80), Size = UDim2.fromOffset(260, 22), BackgroundTransparency = 1, Text = "",
		Font = Enum.Font.GothamBold, TextSize = 15, TextColor3 = C.text, TextXAlignment = Enum.TextXAlignment.Left, MaxVisibleGraphemes = 0}, stack)
	task.spawn(function()
		local ok, img = pcall(function() return Players:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100) end)
		if ok and img and av.Parent then
			av.Image = img
			tween(av, {Size = UDim2.fromOffset(40, 40), ImageTransparency = 0}, 0.4, Enum.EasingStyle.Back)
		end
	end)

	-- чек-лист модулей: статусы с живыми числами
	local ROWS = {
		{"Ядро и ручная ракета", #ROCKET_MODES, "режимов полёта"},
		{"Моя ракета и дракон", #SWARM_MODES, "режимов питомца"},
		{"Спаркеры и надписи", #SPARK_MODES, "режимов огня"},
		{"Мир, небо и шляпы", 11, "неба + 8 шляп"},
		{"Игроки, ESP, бананы", nil, "готово"},
	}
	local rowL, rowR = {}, {}
	for i, r in ipairs(ROWS) do
		local f = make("Frame", {AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromOffset(0, 112 + (i - 1) * 24), Size = UDim2.fromOffset(360, 22), BackgroundTransparency = 1}, stack)
		rowL[i] = make("TextLabel", {Size = UDim2.new(0.55, 0, 1, 0), BackgroundTransparency = 1, Text = r[1], Font = Enum.Font.GothamMedium, TextSize = 13, TextColor3 = C.text,
			TextXAlignment = Enum.TextXAlignment.Left, TextTransparency = 1}, f)
		rowR[i] = make("TextLabel", {Size = UDim2.new(0.45, 0, 1, 0), Position = UDim2.fromScale(0.55, 0), BackgroundTransparency = 1, Text = "◌", Font = Enum.Font.GothamBold, TextSize = 13,
			TextColor3 = C.dim, TextXAlignment = Enum.TextXAlignment.Right, TextTransparency = 1}, f)
	end
	local bar = make("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(0, 252), Size = UDim2.fromOffset(360, 8), BackgroundColor3 = Color3.fromRGB(215, 221, 240), BackgroundTransparency = 1, BorderSizePixel = 0}, stack)
	round(bar, 4)
	local fill = make("Frame", {Size = UDim2.fromScale(0, 1), BackgroundColor3 = C.accent, BorderSizePixel = 0}, bar)
	round(fill, 4)
	make("UIGradient", {Color = ColorSequence.new(C.accent, Color3.fromRGB(190, 100, 255))}, fill)
	local pct = make("TextLabel", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(0, 276), Size = UDim2.fromOffset(120, 18), BackgroundTransparency = 1, Text = "0%",
		Font = Enum.Font.GothamBlack, TextSize = 14, TextColor3 = C.accent, TextTransparency = 1}, stack)
	local skipB = make("TextButton", {AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -16, 1, -14), Size = UDim2.fromOffset(150, 30), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0,
		Text = (DEVICE == "ПК") and "Пропустить  ▸  Space" or "Пропустить  ▸", Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = C.dim, AutoButtonColor = false, ZIndex = 7}, ov)
	round(skipB, 15)
	stroke(skipB, Color3.fromRGB(208, 215, 240), 1, 0)

	local function shock(sz)
		local r = make("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(0, -130), Size = UDim2.fromOffset(40, 40), BackgroundTransparency = 1}, stack)
		round(r, 2000)
		local st = stroke(r, C.accent, 5, 0)
		tween(r, {Size = UDim2.fromOffset(sz, sz)}, 1, Enum.EasingStyle.Quad)
		tween(st, {Transparency = 1, Thickness = 1}, 1)
		task.delay(1.05, function() r:Destroy() end)
	end
	local function confetti()
		for _ = 1, 56 do
			local sz = math.random(6, 13)
			local c = make("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.42), Size = UDim2.fromOffset(sz, sz),
				BackgroundColor3 = Color3.fromHSV(math.random(), 0.55, 1), BorderSizePixel = 0, Rotation = math.random(0, 180), ZIndex = 6}, ov)
			round(c, 2)
			local a, d = math.random() * 6.28, math.random(180, 600)
			tween(c, {Position = UDim2.new(0.5, math.cos(a) * d, 0.42, math.sin(a) * d * 0.7 + 120), BackgroundTransparency = 1, Rotation = math.random(-360, 360)}, 1.2, Enum.EasingStyle.Quad)
			task.delay(1.25, function() c:Destroy() end)
		end
	end
	local function finish()
		if finished then return end
		finished = true
		for _, c in ipairs(iconns) do pcall(function() c:Disconnect() end) end
		introActive = false
		tween(ov, {GroupTransparency = 1}, 0.55)
		task.delay(0.6, function() ov:Destroy() end)
		onDone()
	end
	skipB.MouseButton1Click:Connect(function() skipped = true; finish() end)
	table.insert(iconns, ov.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then skipped = true; finish() end
	end))
	table.insert(iconns, UserInputService.InputBegan:Connect(function(i)
		if i.KeyCode == Enum.KeyCode.Space or i.KeyCode == Enum.KeyCode.Return or i.KeyCode == Enum.KeyCode.Escape then skipped = true; finish() end
	end))

	task.spawn(function()
		local function pause(t)
			local e, T = 0, t * K
			while e < T and not skipped do e += task.wait() end
			return skipped
		end
		local function type_(lbl, text, dur)
			lbl.Text = text
			lbl.MaxVisibleGraphemes = 0
			local n = utf8.len(text) or #text
			for g = 1, n do
				if skipped then return end
				lbl.MaxVisibleGraphemes = g
				task.wait(dur * K / n)
			end
		end
		if pause(0.2) then return end
		tween(logo, {Size = UDim2.fromOffset(96, 96)}, 0.7, Enum.EasingStyle.Back)
		tween(ring, {Size = UDim2.fromOffset(130, 130)}, 0.9, Enum.EasingStyle.Back)
		tween(fl, {TextSize = 58}, 0.7, Enum.EasingStyle.Back)
		if pause(0.5) then return end
		shock(520)
		for i, l in ipairs(letters) do
			task.delay((i - 1) * 0.07 * K, function()
				if not finished then tween(l, {Position = UDim2.fromOffset(0, 0), Rotation = 0, TextTransparency = 0}, 0.6, Enum.EasingStyle.Back) end
			end)
		end
		if pause(0.85) then return end
		for i, g in ipairs(shines) do
			task.delay((i - 1) * 0.06 * K, function()
				if not finished then tween(g, {Offset = Vector2.new(1.2, 0)}, 0.9, Enum.EasingStyle.Quad) end
			end)
		end
		tween(sub, {TextTransparency = 0}, 0.4)
		task.spawn(function() type_(gl, greet .. ", " .. player.DisplayName .. "!", 0.6) end)
		if pause(0.5) then return end
		tween(bar, {BackgroundTransparency = 0}, 0.3)
		tween(pct, {TextTransparency = 0}, 0.3)
		for i, r in ipairs(ROWS) do
			tween(rowL[i], {TextTransparency = 0}, 0.2)
			tween(rowR[i], {TextTransparency = 0}, 0.2)
			tween(fill, {Size = UDim2.fromScale(i / #ROWS, 1)}, 0.3 * K + 0.05, Enum.EasingStyle.Quad)
			pct.Text = math.floor(i / #ROWS * 100) .. "%"
			local lbl = rowR[i]
			for s = 1, 8 do -- число плавно набегает
				if skipped then return end
				lbl.Text = "◌ " .. string.rep("·", s % 4)
				task.wait(0.03 * K)
			end
			lbl.TextColor3 = C.green
			if r[2] then
				for s = 1, 10 do
					if skipped then return end
					lbl.Text = "✓ " .. math.floor(r[2] * s / 10) .. " " .. r[3]
					task.wait(0.02 * K)
				end
			else
				lbl.Text = "✓ " .. r[3]
			end
			if pause(0.06) then return end
		end
		if pause(0.25) then return end
		shock(1100)
		confetti()
		tween(logo, {Size = UDim2.fromOffset(140, 140)}, 0.5, Enum.EasingStyle.Back)
		if pause(0.45) then return end
		finish()
	end)
end

-- ============================ ГЛАВНЫЙ ЦИКЛ ============================
local function updateRocket(dt)
	if unbindCooldown > 0 then unbindCooldown -= dt end

	if activeRocket and (not activeRocket.Parent or not mainPart or not mainPart.Parent) then
		resetCameraToPlayer()
		activeRocket, mainPart, bv, bg = nil, nil, nil, nil
		setFreecam(false)
	end

	-- захват ракеты (запуск только по клику)
	if not activeRocket and unbindCooldown <= 0 then
		local found = findRocketDirectly()
		if found then
			local part = resolvePart(found)
			if part then
				activeRocket, mainPart = found, part
				launched = false
				armedCFrame = mainPart.CFrame

				local look = camera.CFrame.LookVector
				yaw = math.atan2(-look.X, -look.Z)
				pitch = math.asin(math.clamp(look.Y, -1, 1))
				freecamYaw, freecamPitch, lockedYaw, lockedPitch = yaw, pitch, yaw, pitch

				bv = mainPart:FindFirstChild("BodyVelocity") or Instance.new("BodyVelocity")
				bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
				bv.Velocity = Vector3.zero
				bv.Parent = mainPart

				bg = mainPart:FindFirstChild("BodyGyro") or Instance.new("BodyGyro")
				bg.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
				bg.D, bg.P = 150, 5000
				bg.CFrame = armedCFrame
				bg.Parent = mainPart

				camera.CameraType = Enum.CameraType.Scriptable
				resetModeState()
				initialForward = flatten(look)
				wanderDir = initialForward
				ui.hint.Visible = true
			end
		end
	end

	if modeSwitchReset and mainPart and launched then
		resetModeState()
		initialForward = currentForward()
		wanderDir = initialForward
		modeSwitchReset = false
	end

	if not (activeRocket and mainPart and mainPart.Parent) then
		setRkStatus(swarmEnabled and "Статус: включён режим толпы" or "Статус: ищу ракету (BombMissile) рядом…")
		return
	end

	if camera.CameraType ~= Enum.CameraType.Scriptable then
		camera.CameraType = Enum.CameraType.Scriptable
	end

	local t = os.clock() - startTime
	local camYaw = isFreecam and freecamYaw or yaw
	local camPitch = isFreecam and freecamPitch or pitch
	local camDist = 10

	if not launched then
		setRkStatus("Статус: ракета готова. Кликни по ней 🎃")
		if bv and bv.Parent then bv.Velocity = Vector3.zero end
		if bg and bg.Parent and armedCFrame then bg.CFrame = armedCFrame end
	else
		setRkStatus("Статус: полёт · " .. ROCKET_BY_KEY[rocketModeKey].label)
		local velDir, lookDir, speedOverride = computeMode(dt, t)
		local speed = speedOverride or ui.rkSpeed.Get()
		if bg and bg.Parent and lookDir.Magnitude > 0.001 then
			bg.CFrame = CFrame.new(mainPart.Position, mainPart.Position + lookDir) * CFrame.Angles(math.rad(-90), 0, 0)
		end
		if bv and bv.Parent then bv.Velocity = velDir * speed end
		if rocketModeKey == "CINEMATIC" then
			camYaw, camPitch, camDist = t * 0.2, -0.3, 16
		end
	end

	local camRot = CFrame.Angles(0, camYaw, 0) * CFrame.Angles(camPitch, 0, 0)
	local camDir = camRot.LookVector

	if isFirstPerson and not (launched and rocketModeKey == "CINEMATIC") then
		for _, part in ipairs(activeRocket:GetDescendants()) do
			if part:IsA("BasePart") then part.LocalTransparencyModifier = 1 end
		end
		local off = camDir * ((math.max(mainPart.Size.X, mainPart.Size.Y, mainPart.Size.Z) / 2) + 0.5)
		local nose = mainPart.Position + off
		camera.CFrame = CFrame.new(nose, nose + camDir)
	else
		restoreRocketVisibility()
		camera.CFrame = CFrame.new(mainPart.Position) * camRot * CFrame.new(0, 3, camDist) -- 3-е лицо, ракета по центру
	end
end

local function onRender(dt)
	local hrp = getHRP()
	local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if hrp and hum and hum.Health > 0 and showBodyBox then
		fakeBoxPart.CFrame = hrp.CFrame
		fullBodyBox.Visible = true
	else
		fullBodyBox.Visible = false
	end
	local now = os.clock()
	API.safe("мир", API.worldStep, dt, now)
	API.safe("игроки", API.playersStep, dt, now)
	if ui.footerTick then ui.footerTick(dt) end
	API.safe("питомец", API.swarmStep, dt, now)
	API.safe("ракета", updateRocket, dt)
	API.safe("спаркеры", updateSparklers, dt, now)
end

RunService:BindToRenderStep("FembiixMain", Enum.RenderPriority.Camera.Value + 1, onRender)

if SHOW_INTRO and API.cfg.introMode ~= "off" then
	playIntro(function() setHidden(false); UIK.entrance() end)
end
