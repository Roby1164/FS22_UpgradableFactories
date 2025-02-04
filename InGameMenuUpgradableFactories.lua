InGameMenuUpgradableFactories = {}
local inGameMenuUpgradableFactories_mt = Class(InGameMenuUpgradableFactories)

InGameMenuProductionFrame.UPDATE_INTERVAL = 1000

function InGameMenuUpgradableFactories.new(upgradableFactory)
    local self = setmetatable({}, inGameMenuUpgradableFactories_mt)
    
    self.name = "inGameMenuUpgradableFactories"
    self.upgradableFactories = upgradableFactory

    return self
end

function InGameMenuUpgradableFactories:initialize()
    InGameMenuProductionFrame.updateMenuButtons = Utils.appendedFunction(InGameMenuProductionFrame.updateMenuButtons, InGameMenuUpgradableFactories.updateMenuButtons)
end

function InGameMenuUpgradableFactories:delete()
    InGameMenuUpgradableFactories:superClass().delete(self)
end

function InGameMenuUpgradableFactories:getProductionPoints()
    return g_currentMission.inGameMenu.pageProduction:getProductionPoints()
end

function InGameMenuUpgradableFactories:onButtonUpgrade()
    local pageProduction = g_currentMission.inGameMenu.pageProduction
    _, prodpoint = pageProduction:getSelectedProduction()

    local money = g_farmManager:getFarmById(g_currentMission:getFarmId()):getBalance()
    UFInfo(
        "Request upgrade %s to level %d/%d (%s / %s)",
        prodpoint.owningPlaceable:getName(),
        prodpoint.productionLevel,
        UpgradableFactories.max_level,
        g_i18n:formatMoney(prodpoint.owningPlaceable.upgradePrice),
        g_i18n:formatMoney(money)
    )
    if prodpoint.productionLevel >= UpgradableFactories.max_level then
        g_gui:showInfoDialog({
			text = g_i18n:getText("uf_max_level")
		})
        UFInfo("Production already at max level")
    elseif money >= prodpoint.owningPlaceable.upgradePrice then
        local text = string.format(
            g_i18n:getText("uf_upgrade_dialog"),
            prodpoint.owningPlaceable:getName(),
            prodpoint.productionLevel+1,
            g_i18n:formatMoney(prodpoint.owningPlaceable.upgradePrice)
        )
        g_gui:showYesNoDialog({
            text = text,
            title = "Upgrade Factory",
            callback = InGameMenuUpgradableFactories.onUpgradeConfirm,
            target=InGameMenuUpgradableFactories,
            args=prodpoint
        })
    else
        g_gui:showInfoDialog({
			text = self.l10n:getText(ShopConfigScreen.L10N_SYMBOL.NOT_ENOUGH_MONEY_BUY)
		})
        UFInfo("Not enough money")
    end
end

function InGameMenuUpgradableFactories:onUpgradeConfirm(confirm, prodpoint)
    if confirm then
        g_currentMission:addMoney(-prodpoint.owningPlaceable.upgradePrice, 1, MoneyType.SHOP_PROPERTY_BUY, true, true)
        
        prodpoint.productionLevel = prodpoint.productionLevel + 1
        UpgradableFactories:adjProdPoint2lvl(prodpoint, prodpoint.productionLevel)
     
        g_currentMission.inGameMenu.pageProduction.productionList:reloadData()
        
        UFInfo("Upgrade confirmed")
    else
        UFInfo("Upgrade canceled")
    end
end

function InGameMenuUpgradableFactories:updateMenuButtons()
    local upgradeButtonInfo = {
        profile = "buttonOK",
        inputAction = InputAction.MENU_EXTRA_1,
        text = g_i18n:getText("uf_upgrade"),
        callback = InGameMenuUpgradableFactories.onButtonUpgrade
    }
    table.insert(g_currentMission.inGameMenu.pageProduction.menuButtonInfo, upgradeButtonInfo)
end