local StdUi = LibStub("StdUi")

StdUi:RegisterWidget("NastrandirRaidTools_Attendance", function(self, parent)
    local width = parent:GetWidth() or 800
    local height = 500
    local rowHeight = 20

    local widget = StdUi:Frame(parent, width, height)
    self:InitWidget(widget)
    self:SetObjSize(widget, width, height)

    local title = StdUi:Label(widget, "Attendance", 18, "GameFontNormal", widget:GetWidth() - 20, 24)
    widget.title = title
    StdUi:GlueTop(title, widget, 10, -20, "LEFT")

    local start_raid = StdUi:Dropdown(widget, 300, 24, {})
    widget.start_raid = start_raid
    StdUi:AddLabel(widget, start_raid, "Start", "TOP")
    StdUi:GlueBelow(start_raid, title, 0, -30, "LEFT")

    local end_raid = StdUi:Dropdown(widget, 300, 24, {})
    widget.end_raid = end_raid
    StdUi:AddLabel(widget, end_raid, "End", "TOP")
    StdUi:GlueRight(end_raid, start_raid, 10, 0)

    local analyse = StdUi:Button(widget, 80, 24, "Analyse")
    widget.analyse = analyse
    StdUi:GlueRight(analyse, end_raid, 10, 0)

    local export = StdUi:Button(widget, 80, 24, "Export")
    widget.export = export
    StdUi:GlueRight(export, analyse, 10, 0)

    local configuration = StdUi:Button(widget, 80, 24, "Configuration")
    widget.configuration = configuration
    StdUi:GlueBelow(configuration, title, 0, -30, "RIGHT")

    local raids = StdUi:Button(widget, 80, 24, "Raids")
    widget.raids = raids
    StdUi:GlueLeft(raids, configuration, -10, 0)

    local data = StdUi:Table(widget, title:GetWidth(), 400, rowHeight, {}, {})
    widget.data = data
    StdUi:GlueBelow(data, start_raid, 0, -30, "LEFT")

    function widget:GetRaidList()
        local Attendance = NastrandirRaidTools:GetModule("Attendance")
        local list = Attendance:GetRaidList()
        local options = {}
        for _, uid in ipairs(list.order) do
            table.insert(options, {
                text = list.list[uid],
                value = uid
            })
        end

        return options
    end

    function widget:FilterRaidList(start_date)
        local Attendance = NastrandirRaidTools:GetModule("Attendance")
        local list = Attendance:GetRaidList(start_date)
        local options = {}
        for _, uid in ipairs(list.order) do
            table.insert(options, {
                text = list.list[uid],
                value = uid
            })
        end

        return options
    end

    function widget:AddTooltipData(row, column, text)
        if not widget.tooltip_data then
            widget.tooltip_data = {}
        end

        local key = row .. "_" .. column
        if not widget.tooltip_data[key] then
            widget.tooltip_data[key] = {}
        end

        table.insert(widget.tooltip_data[key], text)
    end

    function widget:SortTooltipData(row, column)
        if not widget.tooltip_data then
            widget.tooltip_data = {}
        end

        local key = row .. "_" .. column
        if not widget.tooltip_data[key] then
            widget.tooltip_data[key] = {}
        end

        table.sort(widget.tooltip_data[key], function(a, b)
            return a.order < b.order
        end)
    end

    function widget:GetTooltipText(row, column)
        if not widget.tooltip_data then
            widget.tooltip_data = {}
        end

        local key = row .. "_" .. column
        if not widget.tooltip_data[key] then
            return
        end

        local text = ""
        for _, line in ipairs(widget.tooltip_data[key]) do
            text = text .. line.text .. "\n"
        end

        return text
    end

    function widget:Analyse()
        local Attendance = NastrandirRaidTools:GetModule("Attendance")
        local Roster = NastrandirRaidTools:GetModule("Roster")

        local start_raid = widget.start_raid:GetValue()
        local end_raid = widget.end_raid:GetValue()
        local attendance_data = Attendance:Analyse(start_raid, end_raid)

        -- Build table
        widget.analytics = Attendance:GetAnalytics()
        widget.roster = Roster:GetRaidmember()
        table.sort(widget.roster, function(a, b)
            local name_a = Roster:GetCharacterName(a)
            local name_b = Roster:GetCharacterName(b)

            return name_a < name_b
        end)

        table.sort(widget.analytics, function(a, b)
            local order_a = Attendance:GetAnalytic(a).order
            local order_b = Attendance:GetAnalytic(b).order

            return order_a < order_b
        end)

        local column_count = table.getn(widget.analytics) + 1
        local columns = {
            {
                header = "Raid member",
                index = "name",
                align = "LEFT",
                width = widget.data:GetWidth() / (column_count)
            }
        }
        for _, analytic_uid in ipairs(widget.analytics) do
            local analytic = Attendance:GetAnalytic(analytic_uid)
            table.insert(columns, {
                header = analytic.name,
                index = analytic_uid,
                align = "CENTER",
                width = widget.data:GetWidth() / (column_count)
            })
        end

        -- Fill table
        widget.tooltip_data = {}
        local data = {}
        for player_index, player_uid in ipairs(widget.roster) do
            local row = {
                name = Roster:GetCharacterName(player_uid)
            }

            for analytic_index, analytic_uid in ipairs(widget.analytics) do
                local analytic = Attendance:GetAnalytic(analytic_uid)
                local str = "0%"
                if attendance_data[player_uid] then
                    local total = attendance_data[player_uid].duration
                    local time = 0

                    for state_uid, state_config in pairs(analytic.states) do
                        local addTime = 0
                        if type(state_config) == "boolean" and state_config then
                            if attendance_data[player_uid].states[state_uid] then
                                addTime = attendance_data[player_uid].states[state_uid].total
                            end
                        elseif type(state_config) == "table" then
                            local toleranceType = state_config.tolerance
                            if toleranceType == "TOTAL" then
                                addTime = attendance_data[player_uid].states[state_uid].total
                            elseif toleranceType == "TOLERANCE" then
                                addTime = attendance_data[player_uid].states[state_uid].tolerance
                            elseif toleranceType == "EXCLUDE_TOLERANCE" then
                                addTime = (attendance_data[player_uid].states[state_uid].total - attendance_data[player_uid].states[state_uid].tolerance)
                            end
                        end

                        time = time + addTime
                        local state = Attendance:GetState(state_uid)
                        widget:AddTooltipData(player_index, analytic_index + 1, {
                            text = string.format("%s %d%%", state.Name, ((addTime / total) * 100) + 0.5),
                            order = state.Order
                        })
                    end

                    str = string.format("%d%%", ((time / total) * 100) + 0.5)
                    widget:SortTooltipData(player_index, analytic_index)
                end

                row[analytic_uid] = str
            end

            table.insert(data, row)
        end

        widget.data:SetHeight((#data + 1) * rowHeight)
        widget.data:SetColumns(columns)
        widget.data:SetData(data)
        widget.data:DrawTable()
    end

    function widget:Export()
        local line = ""

        for c=1, table.getn(widget.data.columns) do
             line = line .. widget.data.columns[c].header .. ";"
        end
        print(line)

        for r=1, table.getn(widget.data.rows) do
            line = ""
            for c=1, table.getn(widget.data.columns) do
                local cell = widget.data.rows[r][c]
                if c == 1 then
                    line = line .. cell.text:GetText() .. ";"
                else
                    local fixed = string.sub(cell.text:GetText(), 1, string.len(cell.text:GetText()) - 1)
                    line = string.format("%s%d;", line, tonumber(fixed))
                end
            end
            print(line)
        end
    end

    -- Initialize
    local raids = widget:GetRaidList()
    if table.getn(raids) >= 1 then
        widget.start_raid:SetOptions(raids)
        local raid = raids[math.min(12, table.getn(raids))]
        widget.start_raid:SetValue(raid.value, raid.text)

        widget.end_raid:SetOptions(raids)
        widget.end_raid:SetValue(raids[1].value, raids[1].text)

        widget:Analyse()
    end


    widget.start_raid.OnValueChanged = function(self, value)
        local Attendance = NastrandirRaidTools:GetModule("Attendance")
        local date = Attendance:GetRaid(value).date
        local raids = widget:FilterRaidList(date)
        widget.end_raid:SetOptions(raids)
        widget.end_raid:SetValue(raids[1].value, raids[1].text)
    end

    widget.analyse:SetScript("OnClick", function()
        widget:Analyse()
    end)

    widget.export:SetScript("OnClick", function()
        widget:Export()
    end)

    widget.raids:SetScript("OnClick", function()
        local Attendance = NastrandirRaidTools:GetModule("Attendance")
        Attendance:ShowRaidList()
    end)

    widget.configuration:SetScript("OnClick", function()
        local Attendance  = NastrandirRaidTools:GetModule("Attendance")
        Attendance:ShowConfiguration()
    end)

    widget.data:SetScript("OnUpdate", function()
        if widget.data:IsMouseOver() then
            for rowIndex, row in ipairs(widget.data.rows) do
                for columnIndex, cell in pairs(row) do
                    if cell.text:IsMouseOver() then
                        if not widget.tooltip then
                            widget.tooltip = StdUi:FrameTooltip(widget, "", "Attendance_Tooltip", "TOPRIGHT", false, true)
                            widget.tooltip:SetParent(NastrandirRaidTools.window)
                            widget.tooltip:SetFrameLevel(10)
                        end

                        local text = widget:GetTooltipText(rowIndex, columnIndex)
                        if text and text ~= "" then
                            widget.tooltip:SetText(text)
                            widget.tooltip:ClearAllPoints()
                            StdUi:GlueBelow(widget.tooltip, cell.text, widget.tooltip:GetWidth() / 2, -2)
                            widget.tooltip:Show()
                        else
                            widget.tooltip:Hide()
                        end

                        return
                    end
                end
            end
        end

        if widget.tooltip and widget.tooltip:IsShown() then
            widget.tooltip:Hide()
        end
    end)

    return widget
end)