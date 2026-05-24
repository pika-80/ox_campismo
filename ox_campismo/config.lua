Config = {}

-- Itens usáveis (ESX) que spawnam props
Config.CampingItems = {
    'cadeira',
    'tenda',
    'geladeira',
    'mesa',
    'fogueira',
}

-- Props ao colocar cada item
Config.CampProps = {
    tenda = {
        model = 'm23_2_prop_m32_tent_01a',
        label = 'Tenda',
        duration = 5000,
        anim = {
           dict = 'mini@repair',
           clip = 'fixing_a_player',
           flag = 1,
        },
    },
    cadeira = {
        model = 'prop_skid_chair_01',
        label = 'Cadeira',
        duration = 5000,
        anim = {
           dict = 'mini@repair',
           clip = 'fixing_a_player',
           flag = 1,
        },
    },
    geladeira = {
        model = 'v_ret_fh_coolbox',
        label = 'Geleira',
        duration = 4000,
        anim = { dict = 'amb@prop_human_bum_bin@base', clip = 'base' },
    },
    mesa = {
        model = 'prop_table_03',
        label = 'Mesa',
        duration = 5000,
        anim = {
           dict = 'mini@repair',
           clip = 'fixing_a_player',
           flag = 1,
        },
    },
    fogueira = {
        model = 'prop_beach_fire',
        label = 'Fogueira',
        duration = 5000,
        anim = { dict = 'amb@world_human_gardener_plant@male@base', clip = 'base' },
    },
}

-- Geladeira: slots e peso do stash ox_inventory
Config.CoolerStash = {
    slots = 15,
    weight = 50000,
    label = 'Geleira de Camping',
}

-- Assar na fogueira: item cru -> cozido
-- Adiciona linhas aqui quando quiseres novos pratos
Config.GrillRecipes = {
    ['sockeye_salmon'] = {
        result = 'salmon_cooked',
        label = 'Salmão',
        duration = 8000,
    },
    ['rainbow_trout'] = {
        result = 'trout_cooked',
        label = 'Truta',
        duration = 7000,
    },
}