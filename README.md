# Save and Load Demo (Godot 3 version)

Looking for a Godot 4 version?  [See godot4 branch](https://github.com/jhlothamer/save_and_load_demo/tree/godot4)

**NOTE: The previous version of this demo contained a security vulnerability in the use of a Godot resource file to save and load data.  When a resource file is loaded, arbitrary code can be executed, opening up players to attack.  This demo has been updated to save game data in the JSON file format.  Please see [This video from GDQuest](https://youtu.be/j7p7cGj20jU) for details.  Not implemented in this demo, but mentioned below, you can also encrypt game save files to further protect players and, if desirable, prevent cheating.**

This is a demo project for saving and loading game state data in the Godot Engine.  It goes with the following video:  [Saving & Loading Games in Godot (with demo)](https://youtu.be/_gBpk5nKyXU)

This demo goes beyond the ordinary capture of node property values and handles several game state management aspects most demos or tutorials ignore. These are:

- Capturing game state before scenes are changed and re-applying that state once a scene is loaded.
- Capturing the fact that an instanced child scene in a game scene is freed. The instanced child scene is re-freed each time it's parent scene is loaded. This could apply to a boss-like enemy that is added at design time, but needs to disappear from the game once defeated.
- Capturing the instancing of dynamic child scenes (think spawned enemies, etc.). These dynamic child scenes are re-instanced each time the scene is loaded.
- Game state can be either local to a scene (default) or set as global. Global game state allows state updated in one scene to affect another scene. For example, a triggering event in one level causes a barrier to open in another.
- Automatically saving game state to file when a checkpoint is triggered.

With these abilities it's possible to create much larger and richer games consisting of multiple scenes. And of course players can save their progress and restart where they left off later.

## Game State Helper, Transition Manager Addons (9/16/23)

This demo has been updated so that the Game State Helper service and other related scripts/nodes are in the addons folder as an addon.  This makes it easier for developers to pull the service from this demo and into their own projects.  The same has been done to the Transisiton Manager autoload which is used for a fade-out/fade-in effect when switching between scenes.  You are of course free to use this addon as well as any other code you find in this demo.

### Not Using Transition Manager Addon?  READ THIS!

If you do not use the Transition Manager from this project, you must call GameStateService.on_scene_transitioning() before calling the function on SceneTree to change scene.  This causes the service to collect the state of the current scene.  (Note: it is not saved to disk at this time, but is kept in memory.)  This state will be applied to the scene again when it is reloaded.

For example:

    GameStateService.on_scene_transitioning("res://new_scene.tscn")
    get_tree().change_scene_to_file("res://new_scene.tscn")

## How Does It Work

The demo has two central scripts/nodes to do most of the work. The first is an autoload singleton called **GameStateService**. This singleton detects when scenes switched and manages the saving of state from the old scene and the loading of state for the new scene. The second script/node is the **GameStateHelper**. This node is added as a child to any sub-scene/component in the game we want to save game state for. The **GameStateService** looks for these helper nodes and calls into them. The helper nodes also have signals, saving_data and loading_data, that the parent node can connect to and do it's own saving and loading logic.

## How Certain Scenarios Are Handled

### Capturing/Re-applying Game State on Scene Transition
The **GameStateService** singleton listens for newly added nodes to the scene tree. It checks of the node is to root of a new scene. If it is, then it knows to load game state via the helper nodes.

There is no good way to know when a scene is about to be loaded. (The SceneTree class does not have a signal for this even though it provides the scene change function.) So, the demo relies on a TransitionMgr singleton which is used to fade to/from black around a call to the SceneTree.change_scene() function call. Just before this the TransitionMgr singleton emits a signal. When this happens, the **GameStateService** initiates a save of game state for the current scene.

Note that if you decide to use the **GameStateService** singleton in your project that you will also need to copy the TransitionMgr scene and code files. Or you can handle saving game state for changing scenes in a different way.

### Saving and Loading Child Scene/Component Properties Without Writing Code
The **GameStateHelper** node has an array property called "Save Properties". You just need to add property names to the array for the properties you want to save. For example, if you want to save the position of a character in your game, just add "global_position" to the array. You can add any other property, custom ones too.

### Doing Custom Logic During Saving and Loading Game State
As mentioned above, it's possible to handle the saving and loading of game state data yourself if boiling down the state data to properties doesn't work in your situation.  For this the **GameStateHelper** node provides two signals, saving_data() and loading_data(), that can be connected to. These signals have a single parameter that is the game state dictionary for the scene. All you need to do is store/retrieve data in this dictionary.

### Capturing the Fact That an Instanced Child Scene is Freed
The **GameStateHelper** class emits a signal when it exits the scene tree. This signal is handled by the **GameStateService** singleton. This way the service knows when the instanced child scene is freed. At the time of tree exit an object is created with the data needed so that when the scene is re-loaded, the instanced child scene is freed.

### Capturing the Instancing of Dynamic Child Scenes
There is a flag on the **GameStateHelper** called "Dynamic Instance". Check this on the helper node when the scene will be spawned or dynamically added to a game scene. This will cause the filename of the child scene to be saved as part of the game state. With this information the node will be re-instanced and re-added to the game scene.

### Pass Game State Between Scenes
When you need to pass game state between scenes - for example a trigger in one scene causes a change in another - you need to use the global game state. You can do this by checking the "Global" property on the helper, or calling the **GameStateService**'s set_global_state_value() and get_global_state_value() functions.

### Saving Game State to Disk
The demo has the ability to save the game state. Whenever this happens, the current game state is re-captured to get the latest values and then saved off in a JSON file (.json). Along with the JSON file a ".dat" file is created that contains an md5 hash of the save game file. This is used during loading to see if the save game has been changed.

Note that this type of security is really only meant to keep from loading a file that was accidentally modified or somehow became corrupted on disk. A knowledgeable user could easily make modifications and update the md5 hash. You may wish to switch to using a binary file - or even save the file with a password. These measures would further secure the file.

### Loading Game State from Disk
The **GameStateService** can load saved games from disk as well. While it does this it checks to see if the saved game JSON file contents have been altered by re-computing it's md5 hash and checking it against the hash stored in the .dat file that was save along side it.

The service also takes a FuncRef object which is called with the current scene found in the game state data. This function should change to or transition to this current scene.

### Automically Saving Game State to Disk (Checkpoint)
The demo implements a checkpoint as a visible disk icon with the label "checkpoint".  Passing the demo game character over it will start the checkpoint save.  This is handled like regular saves except the files saved end with "autosave" before the file extensions.  A disk also appears in the top right corner of the screen.  On some systems this saving process is so fast that the disk is not visible, so an animation was added when the disk is dismissed at the end of saving to ensure it is visible.

Credits:
-----------
Fonts:<br>
Cooper Hewitt<br>
https://fontlibrary.org/en/font/cooper-hewitt<br>
by Chester Jenkins<br>
License: OFL (SIL Open Font License) (http://scripts.sil.org/OFL)

