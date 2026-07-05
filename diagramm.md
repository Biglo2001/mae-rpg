classDiagram
    direction TB

    %% --- DATEN MODELLE ---
    class ChatMessage {
        +String text
        +bool isUser
        +ChatMessage(String text, bool isUser)
    }

    class GameSettings {
        +String charName
        +String gender
        +String difficulty
        +String setting
        +bool usePredefinedAdventure
        +GameSettings(String charName, String gender, String difficulty, String setting, bool usePredefinedAdventure)
        +toJson() Map~String, dynamic~
    }

    class InventoryItem {
        +String name
        +String description
        +int quantity
        +IconData icon
        +Color iconColor
        +InventoryItem(String name, String description, int quantity, IconData icon, Color iconColor)
    }

    %% --- FLUTTER WIDGETS & STATES ---
    class ChatBotApp {
        +build(BuildContext context) Widget
    }

    class StartScreen {
        +build(BuildContext context) Widget
        -_buildMenuButton(String text, VoidCallback onTap) Widget
    }

    class SetupScreen {
        +createState() State~SetupScreen~
    }

    class _SetupScreenState {
        +TextEditingController _nameController
        +String _selectedGender
        +String _selectedDifficulty
        +String _selectedSetting
        +bool _isPredefined
        +build(BuildContext context) Widget
        -_buildLabel(String text) Widget
        -_buildTextField(TextEditingController controller, String hint) Widget
        -_buildDropdown(List~String~ items, String current, Function onChanged) Widget
    }

    class ChatScreen {
        +GameSettings settings
        +createState() State~ChatScreen~
    }

    class _ChatScreenState {
        +TextEditingController _messageController
        +ScrollController _scrollController
        +GlobalKey~ScaffoldState~ _scaffoldKey
        +String _apiKey
        +List~ChatMessage~ _messages
        +List~InventoryItem~ _inventory
        +initState() void
        -_initInventory() void
        -_fetchRealAIResponse(String userMessage) Future~String~
        -_sendMessage(String text) void
        -_scrollToBottom() void
        +build(BuildContext context) Widget
        -_buildFantasyDrawer() Widget
        -_buildDrawerItem(IconData icon, String title, bool isStatus, bool isInventory) Widget
        -_buildHorizontalScrollBubble(ChatMessage message) Widget
    }

    class StatusScreen {
        +GameSettings settings
        +build(BuildContext context) Widget
        -_buildStatusRow(IconData icon, String label, String value) Widget
    }

    class InventoryScreen {
        +List~InventoryItem~ inventory
        +build(BuildContext context) Widget
    }

    class MapScreen {
        %% Aus screens/map_screen.dart importiert
    }

    class GameMenuDetailScreen {
        +String title
        +build(BuildContext context) Widget
    }

    %% --- BEZIEHUNGEN & VERKNÜPFUNGEN ---
    ChatBotApp ..> StartScreen : "startet mit"
    StartScreen ..> SetupScreen : "navigiert zu (Spiel Erstellen)"
    StartScreen ..> ChatScreen : "lädt Spiel mit Default-Settings"
    SetupScreen --> _SetupScreenState : "erzeugt"
    _SetupScreenState ..> GameSettings : "erstellt"
    _SetupScreenState ..> ChatScreen : "navigiert zu (übergibt neue Settings)"
    
    ChatScreen --> _ChatScreenState : "erzeugt"
    _ChatScreenState --> "1" GameSettings : "nutzt für Kontext & API"
    _ChatScreenState *-- "*" ChatMessage : "besitzt (Komposition von Nachrichten)"
    _ChatScreenState *-- "*" InventoryItem : "besitzt (Komposition von Items)"
    
    _ChatScreenState ..> StatusScreen : "öffnet per Drawer"
    _ChatScreenState ..> InventoryScreen : "öffnet per Drawer"
    _ChatScreenState ..> MapScreen : "öffnet per Drawer"
    _ChatScreenState ..> GameMenuDetailScreen : "öffnet per Drawer"
    
    StatusScreen --> "1" GameSettings : "zeigt Details von"
    InventoryScreen --> "*" InventoryItem : "stellt dar"