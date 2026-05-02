-- Slash Commands
SLASH_CRAFTPAD1 = "/craftpad"
SLASH_CRAFTPAD2 = "/cp"

SlashCmdList["CRAFTPAD"] = function(msg)
    msg = string.lower(msg or "")

    if msg == "" then
        Craftpad.UI.ToggleMainFrame()
    elseif msg == "community" or msg == "comm" then
        Craftpad.Community.Frame.Toggle()
    elseif msg == "help" then
        print("Craftpad Commands:")
        print("/cp              - Liste des objets housing")
        print("/cp community    - Métiers de la communauté")
        print("/cp help         - Afficher cette aide")
    else
        print("Craftpad: commande inconnue. Tapez /cp help pour l'aide.")
    end
end
