local StdUi = LibStub("StdUi")

StdUi:RegisterWidget("NastrandirRaidTools_Attendance_RaidRecordingStateColumn", function(self, parent, width, height)
    local widget = StdUi:NastrandirRaidTools_Roster_ColumnFrame(parent, width, height)
    self:InitWidget(widget)
    self:SetObjSize(widget, width, height)
    widget:HideAddButton()
    widget.members = {}

    function widget:SetUID(uid)
        widget.uid = uid
    end

    function widget:GetUID()
        return widget.uid
    end

    function widget:AddPlayer(player, silently)
        local Attendance = NastrandirRaidTools:GetModule("Attendance")
        local Roster = NastrandirRaidTools:GetModule("Roster")
        local main_uid = Roster:GetMainUID(player)

        if not Attendance:IsStateTrackingAlts(widget.uid) and player ~= main_uid then
            widget:AddPlayer(main_uid, silently)
        elseif not widget:FindPlayer(player) then
            local Roster = NastrandirRaidTools:GetModule("Roster")
            table.insert(widget.members, {
                uid = player,
                name = Roster:GetCharacterName(player),
                class = Roster:GetCharacterClass(player),
                role = Roster:GetCharacterRole(player)
            })

            if not silently then
                widget:OnPlayerAdded(player)
            end

            widget:CreatePlayerButtons()
        end
    end

    function widget:AddPlayerSilently(player)
        widget:AddPlayer(player, true)
    end

    function widget:OnPlayerAdded(player)
        if widget.playerAddedCallback then
            widget.playerAddedCallback(widget.uid, player)
        end
    end

    function widget:SetPlayerAddedCallback(func)
        widget.playerAddedCallback = func
    end

    function widget:lockButtons()
        widget.buttons_locked = true
    end

    function widget:unlockButtons()
        if widget.buttons_locked then
            widget.buttons_locked = false
            widget:CreatePlayerButtons()
        end
    end

    widget.createButton = function (uid, name, class)
        return StdUi:NastrandirRaidTools_Attendance_RaidRecordingPlayer(widget.content.child, uid, name, class)
    end

    function widget:ReleaseButtons()
        for index, member in ipairs(widget.members or {}) do
            if member.button then
                table.insert(widget.unusedButtons, member.button)
                member.button:Hide()
                member.button:ClearAllPoints()
                member.button = nil
            end
        end
    end

    function widget:CreatePlayerButtons()
        if widget.buttons_locked then
            return
        end

        if widget.sortCallback then
            table.sort(widget.members, widget.sortCallback)
        end

        widget:ReleaseButtons()
        local Roster = NastrandirRaidTools:GetModule("Roster")
        local lastButton
        for index, member in ipairs(widget.members) do
            local button = widget:GetClassButton(member)
            button:SetColumnContainer(widget.column_container)
            button:SetRoster(widget.roster)
            button:SetColumn(widget)
            member.button = button
            button:Show()

            if lastButton then
                StdUi:GlueBelow(button, lastButton, 0, 0)
            else
                StdUi:GlueTop(button, widget.content.child, 0, 0, "LEFT")
            end

            lastButton = button
        end

        widget:SetCount(#widget.members)
    end

    function widget:SetSortCallback(func)
        widget.sortCallback = func
    end

    function widget:SetDropTarget(state)
        if state then
            widget:SetBackdropColor(0.415, 0.745, 0.905, 0.4)
        else
            widget:SetBackdropColor(0, 0, 0, 0)
        end
    end

    function widget:RemovePlayer(uid)
        local pos = widget:FindPlayer(uid)

        if pos then
            local member = widget.members[pos]
            if member.button then
                table.insert(widget.unusedButtons, member.button)
                member.button:ClearAllPoints()
                member.button:Hide()
                member.button = nil
            end
            table.remove(widget.members, pos)

            widget:CreatePlayerButtons()
        end
    end

    function widget:FindPlayer(uid)
        if not widget.members then
            widget.members = {}
        end

        for index, member in ipairs(widget.members) do
            if uid == member.uid then
                return index
            end
        end
    end

    function widget:SetColumnContainer(container)
        widget.column_container = container
    end

    function widget:SetRoster(roster)
        widget.roster = roster
    end

    function widget:RemovePlayerByMain(player_uid)
        local pos = widget:FindPlayerByMain(widget:GetMainUID(player_uid))

            if pos then
                local member = widget.members[pos]
                if member.button then
                    table.insert(widget.unusedButtons, member.button)
                    member.button:ClearAllPoints()
                    member.button:Hide()
                    member.button = nil
                end
                table.remove(widget.members, pos)

                widget:CreatePlayerButtons()
            end
    end

    function widget:GetMainUID(player_uid)
        local Roster = NastrandirRaidTools:GetModule("Roster")
        return Roster:GetMainUID(player_uid)
    end

    function widget:FindPlayerByMain(main_uid)
        if not widget.members then
            widget.members = {}
        end

        for index, member in ipairs(widget.members) do
            local compare = widget:GetMainUID(member.uid)
            if main_uid == compare then
                return index
            end
        end
    end

    function widget:AreAltsAllowed()
        local Attendance = NastrandirRaidTools:GetModule("Attendance")
        return Attendance:IsStateTrackingAlts(widget.uid)
    end

    function widget:CloseContextMenus()
        if widget.members then
            for index, member in ipairs(widget.members) do
                if member.button then
                    member.button:CloseContextMenu()
                end
            end
        end
    end

    function widget:ReleaseAllMember()
        local member_list = {}
        for _, member in ipairs(widget.members or {}) do
            table.insert(member_list, member.uid)
        end

        widget:lockButtons()
        for _, uid in ipairs(member_list) do
            widget:RemovePlayer(uid)
        end
        widget:unlockButtons()
    end

    return widget
end)