Config = {}
Config.CoreName = "qb-core"
Config.JobName = "bondsman"
Config.PoliceJobName = "police"
Config.TabletItem = "bondsman_tablet"
Config.MeetingLocation = vector4(1828.67, 2586.57, 46.01, 275.59)
Config.ExitJailLocation = vector4(1848.99, 2585.97, 45.67, 270.03)
Config.CantLeaveRadius = 10 --If they leave this far from the meeting location, they will be teleported back
Config.LeaveJailEvent = 'prison:client:Leave'
Config.Blip = {
    enabled = true,
    coords = vector3(714.94, -964.49, 30.4),
    sprite = 253,
    color = 6,
    scale = 0.65,
    name = 'Bail Bondsman CO'
}
Config.Laptop = {
    target = {
        coords = vector3(707.23, -966.9, 30.41),
        heading = 182,
        label = "View Outstanding Bills"
    }
}
Config.BailPayments = {
    target = {
        coords = vector3(716.83, -962.4, 30.4),
        heading = 0,
        label = "Make Bail Payment"
    },
    ped = {
        coords = vector4(716.83, -962.4, 29.4, 188.64),
        model = 'a_m_m_hasjew_01' -- Find all ped models at https://docs.fivem.net/docs/game-references/ped-models/
    },
}
Config.Armory = {
    enabled = true,
    label = "Bondsman Armory",
    slots = 40,
    target = {
        coords = vector3(706.03, -960.91, 30.4),
        heading = 90,
        label = "Open Bondsman Armory"
    },
    items = {
        {name = "weapon_combatpistol", price = 1000, amount = 50, type = "weapon", slot = 1, authorizedGrades = {1, 2, 3}, info = {}},
        {name = "pistol_ammo", price = 50, amount = 50, type = "item", slot = 2, authorizedGrades = {0, 1, 2, 3}, info = {}},
        {name = "handcuffs", price = 50, amount = 50, type = "item", slot = 3, authorizedGrades = {0, 1, 2, 3}, info = {}},
        {name = "bondsman_tablet", price = 100, amount = 50, type = "item", slot = 4, authorizedGrades = {0, 1, 2, 3}, info = {}},
    }
}