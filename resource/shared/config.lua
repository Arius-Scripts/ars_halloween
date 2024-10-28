Config                  = {}
Config.ScareProbability = 5 -- max 100.0
Config.MaxPumpkinSpawns = 20

Config.Plate            = {
    pattern = "AAA 777",
    maxLetters = 7
}
Config.PumpkinModel     = `jackolantern`
Config.Progress         = {
    pumpkin = {
        duration = 2000,
        label = 'Collecting',
        useWhileDead = false,
        canCancel = true,
        disable = {
            car = true,
        },
        anim = {
            dict = 'pickup_object',
            clip = 'pickup_low',
            flag = 4,
        },
    },
    zombie = {
        duration = 2000,
        label = 'Examaning Zombie',
        useWhileDead = false,
        canCancel = true,
        disable = {
            car = true,
            move = true,
        },
        anim = {
            dict = 'amb@medic@standing@tendtodead@idle_a',
            clip = 'idle_a'
        },
    }
}


Config.BonusRewards = {
    pumpkins = {
        [30] = {
            items = {
                { name = "witch_brew", minQuantity = 1, maxQuantity = 2 },
                { name = "candy_corn", minQuantity = 5, maxQuantity = 10 },
                { name = "scary_mask", minQuantity = 1, maxQuantity = 1 },
            },
            vehicles = {
                { model = "club", modifications = {}, chance = 5 },
            },
        },
        [80] = {
            items = {
                { name = "golden_pumpkin", minQuantity = 1, maxQuantity = 1 },
                { name = "pumpkin_spice",  minQuantity = 1, maxQuantity = 3 },
            },
            vehicles = {
                { model = "banshee", modifications = {}, chance = 10 },
            },
        },
        [100] = {
            items = {
                { name = "legendary_armor", minQuantity = 1, maxQuantity = 1 },
            },
            vehicles = {
                { model = "zombiea", modifications = {}, chance = 5 },
            },
        },
    },
    zombies = {
        [30] = {
            items = {
                { name = "vampire_fang", minQuantity = 1, maxQuantity = 1 },
                { name = "witch_brew",   minQuantity = 1, maxQuantity = 2 },
            },
            vehicles = {
                { model = "phantom", modifications = {}, chance = 5 },
            },
        },
        [80] = {
            items = {
                { name = "golden_zombie", minQuantity = 1, maxQuantity = 1 },
                { name = "dark_amulet",   minQuantity = 1, maxQuantity = 1 },
            },
            vehicles = {
                { model = "banshee", modifications = {}, chance = 10 },
            },
        },
        [100] = {
            items = {
                { name = "legendary_armor", minQuantity = 1, maxQuantity = 1 },
                { name = "ethereal_sword",  minQuantity = 1, maxQuantity = 1 },
            },
            vehicles = {
                { model = "adder", modifications = {}, chance = 2 },
            },
        },
    }
}

Config.SpookyZones = {
    {
        zone = {
            coords = vector3(-1107.36, -1549.64, 4.36),
            radius = 100.0,
        },
        blip = {
            name = 'Spooky Zone',
            type = 429,
            scale = 0.8,
            color = 17,
        },
        shop = {
            coords = vector4(-1119.92, -1582.96, 7.68, 359.6),
            model = "u_m_y_zombie_01",
            items = {
                { name = "pumpkin_spice",   label = "Pumpkin Spice Elixir", description = "A magical brew to enhance your abilities for %s coins.",                  price = math.random(90, 400) },
                { name = "scary_mask",      label = "Scary Mask",           description = "A mask to frighten your enemies for %s coins.",                           price = math.random(100, 520) },
                { name = "blood_potion",    label = "Blood Potion",         description = "A potion to restore your health for %s coins.",                           price = math.random(100, 520) },
                { name = "vampire_fang",    label = "Vampire Fang",         description = "A tooth from a vampire, useful for crafting for %s coins.",               price = math.random(100, 520) },

                { name = "golden_pumpkin",  label = "Golden Pumpkin",       description = "A rare pumpkin said to bring good fortune for %s coins.",                 price = math.random(1000, 4000) },
                { name = "ethereal_sword",  label = "Ethereal Sword",       description = "A sword forged from the essence of the undead for %s coins.",             price = math.random(500, 900) },
                { name = "legendary_armor", label = "Legendary Armor",      description = "Armor that grants protection from dark forces for %s coins.",             price = math.random(500, 900) },
                { name = "dark_amulet",     label = "Dark Amulet",          description = "An amulet that holds dark powers for %s coins.",                          price = math.random(500, 900) },
                { name = "golden_zombie",   label = "Golden Zombie Token",  description = "A token representing a rare zombie for %s coins.",                        price = math.random(500, 900) },
                { name = "witch_brew",      label = "Witch's Brew",         description = "A potion brewed by witches, filled with mysterious powers for %s coins.", price = math.random(500, 900) },
                { name = "candy_corn",      label = "Candy Corn",           description = "Sweet treats perfect for Halloween celebrations for %s coins.",           price = math.random(500, 900) },
            }
        },

        pumpkins = {
            items = {
                { name = "money",         minQuantity = 50, maxQuantity = 150 },
                { name = "burger",        minQuantity = 2,  maxQuantity = 10 },
                { name = "bandage",       minQuantity = 1,  maxQuantity = 5 },
                { name = "pumpkin_spice", minQuantity = 1,  maxQuantity = 3 },
                { name = "scary_mask",    minQuantity = 1,  maxQuantity = 1 },
            },
            vehicles = {
                { model = "bf400", modifications = {}, chance = 5 },
                { model = "club",  modifications = {}, chance = 3 },
            },
        },
        zombies = {
            items = {
                { name = "money",        minQuantity = 50, maxQuantity = 150 },
                { name = "bandage",      minQuantity = 1,  maxQuantity = 3 },
                { name = "blood_potion", minQuantity = 1,  maxQuantity = 2 },
                { name = "vampire_fang", minQuantity = 1,  maxQuantity = 2 },
            },
            vehicles = {
                { model = "panto", modifications = {}, chance = 5 },
            },
        }
    },
}



lib.locale()
L = locale
