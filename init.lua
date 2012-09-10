---------------------------------------------------------------------------
-- @author Fabian Ezequiel Gallina &lt;fabian@anue.biz&gt;
-- @copyright 2012 Fabian Ezequiel Gallina
-- @license GNU GPLv3 license.
-- @url http://awesome.naquadah.org/wiki/index.php?title=Swifty
-- @release 0.1
---------------------------------------------------------------------------

local awful = require("awful")
local beautiful = require("beautiful")
local ipairs = ipairs
local pairs = pairs
local table = table
local type = type
local capi = {
    client = client,
    mouse = mouse,
    root = root,
    screen = screen
}

--- Dynamic tagging library for awesome.
-- The approach of this library is similar to shifty but it tries to keep as
-- compatible as possible with standard `awful.rules` since the rules for
-- clients and tags follow the same structure.
-- <p> rules.clients and rules.tags are a list of hash tables with the
-- form:</p>
-- <pre>
--     {
--         [rule|rule_any] = MATCH_TABLE,
--         [except|except_any] = EXCEPT_TABLE,
--         properties = PROPERTIES_TABLE
--     }
-- </pre>
-- <p>`rule` is table that might be empty to match anything or contain one or
-- more of the following keyword:</p>
-- <ul>
--   <li>class (string): match clients by WM_CLASS*</li>
--   <li>instance (string): match clients by instance*</li>
--   <li>name (string): match things by its name</li>
--   <li>role (string): match clients by its role*</li>
--   <li>type (string): match clients by its type*</li>
-- </ul>
--
-- <p>Those marked with * are only available for rules.clients only and the xprop
-- program might help to find proper values. See:
-- http://wiki.compiz.org/WindowMatching</p>
--
-- <p>Alternatively, `rule_any` exists and allows matching several things at the
-- same time by making its keys to receive a list of strings to match instead.</p>
--
-- <p>`except` and `except_any` are analog to `rule` and `rule_any` respectively,
-- except they exclude matching clients.</p>
--
-- <p>Finally the `properties` table is a hash table of properties to apply to
-- the matched element.</p>
--
-- <p>Properties available for clients (not comprehensive):</p>
-- <ul>
--     <li>border_color (string): The client border color</li>
--     <li>border_width (int): The client border width</li>
--     <li>buttons (table): The client specific mouse bindings</li>
--     <li>class (string): The client class*</li>
--     <li>floating (bool): If client must be floating</li>
--     <li>focus (bool): The client focus</li>
--     <li>instance (string): The client instance*</li>
--     <li>keys (table): The client specific key bindings</li>
--     <li>maximized_horizontal (bool): If client must be maximized horizontaly</li>
--     <li>maximized_vertical (bool): If client must be maximized vertically</li>
--     <li>minimized (bool): If client must be minimized</li>
--     <li>name (string): The client name*</li>
--     <li>ontop (bool): If client must be on top</li>
--     <li>screen (int): The client current screen</li>
--     <li>size_hints_honor (bool): If client size limits hints should be used</li>
--     <li>switchtotag (bool): If client's tag must be the selected on launch</li>
--     <li>tag (string): The name of the tag to place it</li>
--     <li>urgent (bool): If the urgent hint should be added when launched</li>
-- </ul>
-- <p>Properties available for tags (not comprehensive):</p>
-- <ul>
--     <li>icon (string): The tag icon</li>
--     <li>mwfact (float): The Master width factor</li>
--     <li>name (string): The tag name*</li>
--     <li>ncol (int): The number of column windows</li>
--     <li>nmaster (int): The number of master windows</li>
--     <li>persistent (bool): If tag must not be deleted after clients are closed</li>
--     <li>position (int): The tag position</li>
--     <li>screen (int): The tag current screen</li>
--     <li>selected (bool): If tag is selected</li>
-- </ul>
-- <p>Those marked with * are read only but listed for reference.</p>
--
-- <p>Here it is a really small setup example:</p>
-- <pre>rules = {}</pre>
-- <pre>rules.clients = {</pre>
-- <pre>    -- All clients will match this rule.</pre>
-- <pre>    {</pre>
-- <pre>        rule = {},</pre>
-- <pre>        properties = {</pre>
-- <pre>            border_width = beautiful.border_width,</pre>
-- <pre>            border_color = beautiful.border_normal,</pre>
-- <pre>            focus = true,</pre>
-- <pre>            size_hints_honor = false,</pre>
-- <pre>            keys = clientkeys,</pre>
-- <pre>            buttons = clientbuttons,</pre>
-- <pre>            floating = false</pre>
-- <pre>        },</pre>
-- <pre>    },</pre>
-- <pre>    -- This is for Emacs only</pre>
-- <pre>    {</pre>
-- <pre>        rule = { class="Emacs" },</pre>
-- <pre>        properties = {</pre>
-- <pre>            tag = "emacs"</pre>
-- <pre>        }</pre>
-- <pre>    }</pre>
-- <pre>}</pre>
--
-- <pre>rules.tags = {</pre>
-- <pre>    -- All tags will match this rule.</pre></pre>
-- <pre>    {</pre>
-- <pre>        rule = {},</pre>
-- <pre>        properties = {</pre>
-- <pre>            screen = 1</pre>
-- <pre>        },</pre>
-- <pre>    },</pre>
-- <pre>    -- This is for the emacs and www tags only</pre>
-- <pre>    {</pre>
-- <pre>        rule_any = { name="emacs", name="www" },</pre>
-- <pre>        properties = {</pre>
-- <pre>            screen = 2,</pre>
-- <pre>            position = 1</pre>
-- <pre>        }</pre>
-- <pre>    }</pre>
-- <pre>}</pre>
--
-- <code>swifty.init({
--     promptbox=mypromptbox,
--     globalkeys=globalkeys,
--     modkey=modkey,
--     bind_keys=true,
--     bind_numbers=true
-- })
-- </code>

module("swifty")

defaults = {}
defaults.conf = {
    history_limit=10,
    bind_numbers=true,
    bind_keys=true
}

conf = {}
rules = {}
rules.clients = {}
rules.tags = {}

--- Check if a client or tag match a rule.
-- @param thing The client or tag
-- @param rule The rule to check
-- @return True if it matches, false otherwise
function match(thing, rule)
    return awful.rules.match(thing, rule)
end

--- Check if a client or tag match a rule. Multiple can be matched.
-- @param thing The client or tag
-- @param rules The rule to check
-- @return True if at least one rule is matched, false otherwise
function match_any(thing, rule)
    return awful.rules.match_any(thing, rule)
end

--- Get client or tag attributes for matched rules.
-- @param thing The client or tag
-- @return (table) properties, (table) callbacks
local function collect_attributes(thing)
    local rrules = nil
    local ttype = type(thing)
    if ttype == "client" then
        rrules = rules.clients
    elseif ttype == "tag" then
        rrules = rules.tags
    else
        return nil
    end

    local props = {}
    local callbacks = {}
    for _, entry in ipairs(rrules) do
        if (match(thing, entry.rule) or match_any(thing, entry.rule_any)) and
            (not match(thing, entry.except) and
             not match_any(thing, entry.except_any)) then
            if entry.properties then
                for property, value in pairs(entry.properties) do
                    props[property] = value
                end
            end
            if entry.callback then
                table.insert(callbacks, entry.callback)
            end
        end
    end

    return props, callbacks
end

--- Initialize swifty.
-- The only mandatory key in the configuration table is promptbox, which is
-- used for prompts when renaming tags and such.  If globalkeys and modkey are
-- provided then swifty is able to to bind default keys to manage tags and
-- clients.  bind_keys controls wether to bind standard bindings or not.
-- bind_numbers wether to bind number keys combinations to manage tags.
-- @See defaults.conf for a list of default values.
-- @usage swifty.init({
--     promptbox=mypromptbox,
--     globalkeys=globalkeys,
--     modkey=modkey,
--     bind_keys=true,
--     bind_numbers=true,
--     history_limit=10
-- })
-- @param args Configuration table
function init(args)
    conf = awful.util.table.join(defaults.conf, args or {})
    tags.init()

    local globalkeys = conf.globalkeys
    local modkey = conf.modkey

    if conf.bind_numbers and globalkeys and modkey then
        -- Bind all key numbers to tags.
        for i = 1, 9 do
            globalkeys = awful.util.table.join(
                globalkeys,
                -- Select one tag only
                awful.key({ modkey }, "#" .. i + 9,
                          function ()
                              local tags = capi.screen[capi.mouse.screen]:tags()
                              if tags[i] then
                                  awful.tag.viewonly(tags[i])
                              end
                          end
                ),
                -- Select/deselect a tag
                awful.key({ modkey, "Shift" }, "#" .. i + 9,
                          function ()
                              local tags = capi.screen[capi.mouse.screen]:tags()
                              if tags[i] then
                                  awful.tag.viewtoggle(tags[i])
                              end
                          end
                )
            )
        end
    end

    if conf.bind_keys and globalkeys and modkey then
        -- Swifty related tags handling
        globalkeys = awful.util.table.join(
            globalkeys,
            -- Select next screen
            awful.key({modkey}, "Up",
                      commands.focus_next_screen),
            -- Select previous screen
            awful.key({modkey}, "Down",
                      commands.focus_prev_screen),
            -- Move to the left tag
            awful.key({modkey}, "Left",
                      awful.tag.viewprev),
            -- Move the current tag to the right
            awful.key({modkey}, "Right",
                      awful.tag.viewnext),
            -- Add a new tag
            awful.key({modkey, "Shift"}, "a",
                      tags.commands.add),
            -- Delete the current tag if it is empty
            awful.key({modkey, "Shift"}, "d",
                      tags.commands.delete),
            -- Rename the current tag
            awful.key({modkey, "Shift"}, "r",
                      tags.commands.rename),
            -- Move the current tag to the next screen
            awful.key({modkey, "Shift"}, "Up",
                      tags.commands.move_to_next_screen),
            -- Move the current tag to the previous screen
            awful.key({modkey, "Shift"}, "Down",
                      tags.commands.move_to_prev_screen),
            -- Move the current tag to the left
            awful.key({modkey, "Shift"}, "Left",
                      tags.commands.move_left),
            -- Move the current tag to the right
            awful.key({modkey, "Shift"}, "Right",
                      tags.commands.move_right),
            -- Restore all rules for the current tag
            awful.key({modkey, "Shift"}, "e",
                      tags.commands.restore_rules),
            -- Restore the position of the current tag
            awful.key({modkey, "Shift"}, "t",
                      tags.commands.restore_position),
            -- Move the current client to the left
            awful.key({modkey, "Control", "Shift"}, "Left",
                      clients.commands.move_to_left_tag),
            -- Move the current client to the right
            awful.key({modkey, "Control", "Shift"}, "Right",
                      clients.commands.move_to_right_tag),
            -- Restore all rules for the current selected client
            awful.key({modkey, "Control", "Shift"}, "e",
                      clients.commands.restore_rules),
            -- Restore the tag for the current selected client
            awful.key({modkey, "Control", "Shift"}, "t",
                      clients.commands.restore_tag)
        )
    end

    if globalkeys and modkey then
        capi.root.keys(globalkeys)
    end

end

commands = {}

commands._focus_screen = function(direction)
    local num_screens = capi.screen.count()
    local screen = capi.mouse.screen
    local position = screen

    if not direction or direction < 0 then
        position = screen - 1
    else
        position = screen + 1
    end

    -- In case position overflows, cycle
    if position < 1 then
        position = num_screens
    elseif position > num_screens then
        position = 1
    end

    awful.screen.focus(position)
    local tags = capi.screen[position]:tags()
    local selected = awful.tag.selectedlist()
    -- If not tags are selected, select the first available
    if #selected == 0 and #tags > 0 then
        awful.tag.viewonly(tags[1])
    end
end

commands.focus_prev_screen = function()
    commands._focus_screen(-1)
end

commands.focus_next_screen = function()
    commands._focus_screen(1)
end


clients = {}

--- Apply rules to given client.
-- @param client The client to apply rules to
-- @return (client) the modified client, (table) the applied properties
clients.apply_rules = function(client)
    local props, callbacks = collect_attributes(client)
    if not props and not callbacks then return client end

    for property, value in pairs(props) do
        if property == "floating" then
            awful.client.floating.set(client, value)
        elseif property == "tag" then
            local tag = ({tags.get_or_create(value)})[2]
            client:tags({ tag })
            client.screen = tag.screen
        elseif property == "switchtotag" and value and props.tag then
            local tag = ({tags.get_or_create(props.tag)})[2]
            awful.tag.viewonly(tag)
        elseif property == "height" or property == "width" or
                property == "x" or property == "y" then
            local geo = client:geometry();
            geo[property] = value
            client:geometry(geo);
        elseif type(client[property]) == "function" then
            client[property](client, value)
        else
            client[property] = value
        end
    end

    -- If untagged, stick the client on the current one.
    if #client:tags() == 0 then
        awful.tag.withcurrent(client)
    end

    -- Apply all callbacks from matched rules.
    for i, callback in pairs(callbacks) do
        callback(client)
    end

    -- Do this at last so we do not erase things done by the focus
    -- signal.
    if props.focus then
        capi.client.focus = client
    end

    return client, props
end

--- Move a client to a tag.
-- @param client (optional) client to move (defaults to the focused one)
-- @param tag tag object or idx to move the client to
-- @param select if true, select the tag where the app has moved to
-- @return true when the client has moved
clients.move_to_tag = function(client, tag, select)
    if not tag then return nil end
    if not client then
        client = capi.client.focus
    end
    if client then
        if type(tag) == "number" then
            local screen = client.screen
            tag = capi.screen[screen]:tags()[tag]
        end
        if tag then
            awful.client.movetotag(tag, client)
            if select then
                awful.tag.viewonly(tag)
                capi.client.focus = client
            end
            return true
        end
    end
end

--- Tag handling related commands.
clients.commands = {}

--- Move the current focused client to the tag to direction.
-- This is the internal implementation of clients.commands.move_to_left_tag and
-- clients.commands.move_to_right_tag
-- @param direction number, when positive move to right else to left
clients.commands._move_to_tag = function(direction)
    local client = capi.client.focus
    local tag = awful.tag.selected()
    if client and tag and direction and direction ~= 0 then
        local tag_idx = awful.tag.getidx(tag)
        local screen = client.screen
        local tags = capi.screen[screen]:tags()
        local position = tag_idx
        if not direction or direction < 0 then
            position = tag_idx - 1
        else
            position = tag_idx + 1
        end

        -- In case position overflows, cycle
        if position < 1 then
            position = #tags
        elseif position > #tags then
            position = 1
        end

        clients.move_to_tag(client, position, true)
    end
end

--- Move the current focused client to the tag on the left.
clients.commands.move_to_left_tag = function()
    clients.commands._move_to_tag(-1)
end

--- Move the current focused client to the tag on the right.
clients.commands.move_to_right_tag = function()
    clients.commands._move_to_tag(1)
end

--- Reapply all defined rules to the current focused client.
clients.commands.restore_rules = function()
    local client = capi.client.focus
    if client then
        clients.apply_rules(client)
    end
end

--- Move the current focused client to the tag defined in the rules.
clients.commands.restore_tag = function()
    local client = capi.client.focus
    if client then
        local props, _ = collect_attributes(client)
        if props.tag then
            local _, tag = tags.get_or_create(props.tag)
            clients.move_to_tag(client, tag)
        end
    end
end

--- Namespace for tag related functions.
tags = {}

--- Matches string 'name' to tag objects.
-- @param name: tag name to find
-- @param screen: screen to look for tags on
-- @return table of tag objects or nil
tags.find_by_name = function(name, screen)
    if not screen then return nil end
    local ttags = {}
    for _, tag in ipairs(capi.screen[screen]:tags()) do
        if tag.name == name then
            table.insert(ttags, tag)
        end
    end
    if #ttags > 0 then return ttags else return nil end
end

--- Find a specific tag from name, screen and idx.
-- @param name: tag name to find
-- @param screen: screen to look
-- @param idx: (optional) the tag idx
-- @return tag object or nil
tags.find = function(name, screen, idx)
    local ttags = tags.find_by_name(name, screen)
    if ttags then return ttags[idx or 1] end
end

--- Apply rules to given tag.
-- @param tag The tag to apply rules to
-- @return (tag) the modified tag, (table) the applied properties
tags.apply_rules = function(tag)
    local props, callbacks = collect_attributes(tag)
    if not props and not callbacks then return tag end

    -- This is a really important thing to have set beforehand, specially for
    -- position tweaking
    if props and props.screen then
        tag.screen = props.screen
        props.screen = nil
    end

    -- move the tag to the defined position or to the last slot when is not
    -- defined, after that remove it from the list of properties to process so
    -- the auto-property setting does not fail. After setting everything make
    -- position available again.
    awful.tag.setproperty(tag, "position", props.position)
    local position = props and props.position
    local screen = tag.screen
    local ttags = capi.screen[screen]:tags()
    if #ttags > 1 then
        table.sort(
            ttags,
            function(a, b)
                local apos = awful.tag.getproperty(a, "position")
                local bpos = awful.tag.getproperty(b, "position")
                if not apos then
                    if not bpos then
                        return a.name <= b.name
                    else
                        return false
                    end
                else
                    if not bpos then
                        return true
                    else
                        if apos < bpos then
                            return true
                        elseif apos == bpos then
                            return a.name < b.name
                        else
                            return false
                        end
                    end
                end
            end)
        capi.screen[screen]:tags(ttags)
    end
    props.position = nil

    for property, value in pairs(props) do
        if type(tag[property]) == "function" then
            tag[property](tag, value)
        elseif property == "icon" then
            awful.tag.seticon(value, tag)
        elseif property == "mwfact" then
            awful.tag.setmwfact(value, tag)
        elseif property == "ncol" then
            awful.tag.setncol(value, tag)
        elseif property == "nmaster" then
            awful.tag.setnmaster(value, tag)
        else
            awful.tag.setproperty(tag, property, value)
        end
    end

    props.position = position

    for i, callback in pairs(callbacks) do
        callback(tag)
    end

    return tag, props
end

--- Get or create an existing tag.
-- @param name The tag name
-- @param create If set force the creation of the tag even if other exists
-- @return (bool) if created, (tag) the tag, (table) applied properties
tags.get_or_create = function(name, create)
    local screen = capi.mouse.screen

    -- try to find an existing tag matching name
    local ttags = nil
    if not create then
        ttags = tags.find_by_name(name, screen)
    end
    local created = false
    local tag = nil
    if not ttags then
        -- if not matching tags exist or that specific idx is not matching
        -- create a new one.
        for _, t in pairs(awful.tag.new({name}, screen)) do
            tag = t
        end
        -- After creating make it the visible one
        awful.tag.viewonly(tag)
        created = true
    else
        -- Get the first matching tag
        tag = ttags[1]
    end

    if created then
        return created, tags.apply_rules(tag)
    else
        return false, tag, nil
    end
end

--- Create a tag.
-- @param name The tag name
-- @return the created tag object
tags.create = function(name)
    return ({tags.get_or_create(name, true)})[2]
end

--- Move a tag to an absolute position in the screen:tags() table.
-- This is function is pretty much the same as awful.tag.move except it
-- handles corner cases gracefully plus it reorders the params to be the
-- same as everywhere in the swifty api (tag comes first)
-- @param tag tag object to move
-- @param position (optional) Integer absolute position
tags.move = function(tag, position)
    local tag = tag or awful.tag.selected()
    local screen = tag.screen
    local tmp_tags = capi.screen[screen]:tags()
    local focused_client = capi.client.focus

    -- In case position overflows, cycle
    if not position or position < 1 then
        position = #tmp_tags
    elseif position > #tmp_tags then
        position = 1
    end

    for i, t in ipairs(tmp_tags) do
        if t == tag then
            table.remove(tmp_tags, i)
            break
        end
    end

    table.insert(tmp_tags, position, tag)
    capi.screen[screen]:tags(tmp_tags)

    -- Restore previous selected client
    if focused_client then
        capi.client.focus = focused_client
    end
end

--- Move a tag to a given screen.
-- @param tag (optional) tag object to move
-- @param screen Integer screen position
-- @return true is tag has been moved to given screen
tags.move_to_screen = function(tag, screen)
    local tag = tag or awful.tag.selected()
    if tag then
        local num_screens = capi.screen.count()
        if screen > num_screens or num_screens < 0 then
            return false
        end
        local clients = tag:clients()
        tag.screen = screen
        for _, client in pairs(clients) do
            awful.client.movetotag(tag, client)
        end
        return true
    end
end

--- Initialize tags.
-- Takes care of creating persistent tags
tags.init = function()
    for _, rule in pairs(rules.tags) do
        local properties = rule.properties
        local persistent = nil
        local name = nil
        if properties then
            persistent = properties.persistent
        end
        if properties then
            name = properties.name
        end
        -- When there's not an explicit name defined for the persistent tag
        -- try to guess it from the rules
        if not name then
            local rule = rule.rule
            local rule_any = rule.rule_any
            if rule and rule.name then
                name = rule.name
            elseif rule_any and rule_any.name then
                name = rule_any.name[0]
            end
        end
        if persistent and name then
            tags.get_or_create(name)
        end
    end
end

--- Cleanup non persistent empty tags.
-- @param name The client
tags.cleanup = function()
    for screen = 1, capi.screen.count() do
        for _, tag in ipairs(capi.screen[screen]:tags()) do
            if not awful.tag.getproperty(tag, "persistent") and
               not tag.selected and #tag:clients() == 0 then
                awful.tag.delete(tag)
            end
        end
    end
end

--- Tag handling related commands.
tags.commands = {}

--- Prompt for tag name to create.
tags.commands.add = function()
    awful.prompt.run(
        { prompt = "new tag: " }, -- args
        conf.promptbox[capi.mouse.screen].widget, -- promptbox
        tags.create, -- execute callback
        nil, -- completion callback
        awful.util.getdir("cache") .. "/swifty_tags", -- history path
        conf.history_limit,
        nil -- done callback
    )
end

--- Rename a tag.
tags.commands.rename = function()
    local tag = awful.tag.selected()
    if tag then
        awful.prompt.run(
            { prompt = "Rename " .. tag.name .. " to: " }, -- args
            conf.promptbox[capi.mouse.screen].widget, -- promptbox
            -- execute callback
            function (name)
                -- Save the original tag name so it can be restored later
                if not awful.tag.getproperty(tag, "old_name") then
                    awful.tag.setproperty(tag, "old_name", tag.name)
                end
                tag.name = name
            end,
            nil, -- completion callback
            awful.util.getdir("cache") .. "/swifty_tags", -- history path
            conf.history_limit, -- history limit
            nil -- done callback
        )
    end
end

--- Move a tag to the left.
tags.commands.move_left = function()
    local tag = awful.tag.selected()
    if tag then
        tags.move(tag, awful.tag.getidx(tag) - 1)
    end
end

--- Move a tag to the right.
tags.commands.move_right = function()
    local tag = awful.tag.selected()
    if tag then
        tags.move(tag, awful.tag.getidx(tag) + 1)
    end
end


--- Move the current tag to given screen direction.
-- This is the internal implementation of tags.commands.move_to_prev_screen
-- and tags.commands.move_to_next_screen
-- @param direction number, when positive move to right else to left
tags.commands._move_to_screen = function(direction)
    local tag = awful.tag.selected()
    if tag then
        local num_screens = capi.screen.count()
        local screen = capi.mouse.screen
        local position = screen

        if not direction or direction < 0 then
            position = screen - 1
        else
            position = screen + 1
        end

        -- In case position overflows, cycle
        if position < 1 then
            position = num_screens
        elseif position > num_screens then
            position = 1
        end

        tags.move_to_screen(tag, position)
        awful.tag.viewonly(tag)
        awful.screen.focus(position)
    end
end

--- Move a tag to the previous screen.
tags.commands.move_to_prev_screen = function()
    tags.commands._move_to_screen(-1)
end

--- Move a tag to the next screen.
tags.commands.move_to_next_screen = function()
    tags.commands._move_to_screen(1)
end

--- Reapply all defined rules to the current focused tag.
tags.commands.restore_rules = function()
    local tag = awful.tag.selected()
    if tag then
        -- Restore the original tag name before reapplying any rules so they
        -- are matched properly again
        local old_name = awful.tag.getproperty(tag, "old_name")
        if old_name then
            tag.name = old_name
        end
        tags.apply_rules(tag)
    end
end

--- Move the current focused tag to the proper position defined in the rules.
tags.commands.restore_position = function()
    local tag = awful.tag.selected()
    if tag then
        tags.move(tag, awful.tag.getproperty(tag, "position"))
    end
end

--- Delete selected tags with no clients attached.
tags.commands.delete = function()
    for _, tag in pairs(awful.tag.selectedlist()) do
        if #tag:clients() == 0 then
            awful.tag.delete(tag)
        end
    end
end

--- signals.
capi.client.add_signal("manage", clients.apply_rules)
capi.client.add_signal("unmanage", tags.cleanup)
capi.client.remove_signal("manage", awful.tag.withcurrent)

for s = 1, capi.screen.count() do
    awful.tag.attached_add_signal(s, "property::selected", tags.cleanup)
end

-- Local variables:
-- indent-tabs-mode: nil **
-- fill-column: 78 **
-- lua-indent-level: 4 **
-- End:
