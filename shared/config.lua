Config = {}
Config.CoreName = "qb-core"
Config.JobName = "bondsman"
Config.Target = "qb" -- qb or ox supported
Config.Blip = {
    enabled = true,
    coords = vector3(714.94, -964.49, 30.4),
    sprite = 253,
    color = 6,
    scale = 0.65
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
    ped = {
        coords = vector3(706.03, -960.91, 30.4),
        model = 'a_m_m_hasjew_01'
    },
    items = {
        {name = "weapon_combatpistol", price = 1000, amount = 50, type = "weapon", slot = 1, authorizedGrades = {0}, info = {}},
        {name = "pistol_ammo", price = 50, amount = 50, type = "item", slot = 2, authorizedGrades = {0, 1}, info = {}},
        {name = "handcuffs", price = 50, amount = 50, type = "item", slot = 3, authorizedGrades = {0, 1}, info = {}},
    }
}