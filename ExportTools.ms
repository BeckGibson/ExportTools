try (cui.unRegisterDialogBar exporttools)catch()
try (DestroyDialog exporttools)catch()

rollout exporttools "Export Tools"
(
	label lblPivot "Pivot Position"
	button btnTop "Pivot to Top" width:125 tooltip:"Moves pivot to top center and positions to 0,0,0"
	button btnCenter "Pivot to Center" width:125 tooltip: "Moves pivot to center and positions to 0,0,0"
	button btnBottom "Pivot to bottom" width:125 tooltip: "Moves pivot to bottom and positions to 0,0,0"
	label lblBlank0 "" height:20
	label lblCleanUp "Clean Up Tools"
	button btnDefaultMat "Set Default Material" width:125 tooltip: "Assigns object a default material named to match object name"
	button btnCollapse "Collapse Stack" width:125 tooltip: "Collapses modifier stack and converts to Edit Poly"
	button btnUnityReset "Unity Reset" width:125 tooltip: "Resets Object position and rotation for Unity"
	button btnXform "Reset Xform" width:125 tooltip: "Resets Xform for selected objects"
	button btnCombine "Combine Selected" width:125 tooltip:"Combine selected geometry"
	button btnDetach "Detach elements" width:125 tooltip:"Detach elements in selected geometry"
	label lblBlank1 "" height:20
	
	label lblBlank "Tailor Export for:"
	radiobuttons ExportType labels:#("Unity", "UE4","None") tooltip: "Resets object for Unity or UE4 import"
	
	checkbox CheckCombined "Export selection as one file" tooltip: "Exports all selected objects into a single .FBX instead of one file per object"
	checkbox CheckPanel "Show Export settings" tooltip: "Shows the export dialogue box for changing export settings"
	checkbox CheckDirectory "Change Directory" tooltip: "Will prompt you to select a new directory on export"
	checkbox CheckCleanUp "Run Clean Up Tools" tooltip: "Resets objects to 0,0,0 (when not exporting as single file), sets default material, resets transforms"
	checkbox CheckPreserveMat "Preserve Materials" tooltip: "Preserves materials when exporting, overwrites material changes from clean up tools"
	
	button btnExport "Export Selected" width:125 height: 50 tooltip:"Exports according to settings"
	edittext FileNameInput "File Name Overwrite" labelOnTop:true readOnly:true tooltip: "File Name Overwrite for exporting as single file only"
	label lblBlank3 "" height:5	
	checkbox CheckWarnings "Ignore Warnings" tooltip:"Ignore all warning messages associated with this script"
	
	global newDirectory
	global preserveMat = false
	global ToggleWarnings = false

	function CombineElements =
	(
		count = 2
		CombineNode = 1
		
		select $* --select everything		
		selectionArray = selection as Array --create array
		for obj in selectionArray do --for each object in the array
		(
			if superClassOf obj != GeometryClass or obj.isHidden == true then--if it's not geometry
			(
				obj.isFrozen = true --freeze it
			)
		)
		
		convertTo selection Editable_Poly --convert everything to edit poly (that can be converted)
		
		CombineArray = selection as Array --create array of selection
		for start=1 to CombineArray.count do --for however long the array is
		(
			if CombineArray[CombineNode] != undefined and CombineArray[CombineNode].isFrozen == true then --if the combine node is not undefined and is frozen
			(
				while CombineArray[CombineNode] != undefined and CombineArray[CombineNode].isFrozen == true do -- as long as the combine node is not undefined and is frozen
				(
					CombineNode = CombineNode + 1 --advance the array, to find an object that exists and isn't frozen
				)
			)
			if CombineArray[count] != undefined and CombineArray[count].isFrozen == true then --if the object we're trying to combined is not underfined and is frozen
			(
				while CombineArray[count] != undefined and CombineArray[count].isFrozen == true do --as long as it's still frozen
				(
					count = count + 1 --move to the next object in the array to find one that isn't
				)
			)
			if count == CombineNode then --if the object to be combined and the object to combine to are the same
			(
				count = count + 1 --move to the next object in the array for count
			)
			if CombineArray[count] != undefined and CombineArray[count].isFrozen == false then --if the object to combine is not undefined and is not frozen
			(
				polyop.attach CombineArray[CombineNode] CombineArray[count] --attach it to combine node
				count = count + 1 --move onto the next object
			)
		)
	)

	function defaultMat = 
	(
		obj=selection as Array
		if obj.count==0 then (messageBox "Select Objects")
		else
		(
			for items in obj do
			(
				newmat = Standardmaterial() --creates standard material
				newmat.name = items.name as string + "_MAT" --calls material name of object _MAT
				items.material = newmat --assigns the material
			)
		)
	)
	
	function FnXform =
	(
		obj=selection as Array
		if obj.count==0 then (messageBox "Select Objects")
		else
		(
			local parentArray = #() --array for parents of all objects
			local i = 1
			local count = 1
			
			for start=1 to obj.count do
			(
				if obj[count].parent == undefined then --if object doesn't have a parent,
				(
					AppendItem = obj[count] --copy it
					deleteItem obj count --delete original
					append obj AppendItem --append to end of array
				)
				else
				(
					count = count + 1 --check next object in array if first is a child
				)
			)
			for items in obj do
			(
				append parentArray items.parent --adds the parent of an object to the parrent array (adds undefined if no parent)
				items.parent = undefined --sets parent to undefined (deletes parent links in heiracy)
				ResetXForm(items) --reset xform
				collapseStack(items) --collapse modifier stack
			)
			
			for items in obj do
			(
				items.parent = ParentArray[i] --assigns original parent back to object from parent array
				i = i + 1
			)
		)
	)
	
	function UnityReset =
	(
		obj=selection as Array
		if obj.count==0 then (messageBox "Select Objects")
		else
		(
			local parentArray = #() --array for parents of all objects
			local SetRotation = EulerAngles -90 0 0
			local ResetRotation = EulerAngles 90 0 0
			local i = 1
			local count = 1
			
			for start=1 to obj.count do --for number of objects selected
			(
				if obj[count].parent == undefined then --if object doesn't have a parent,
				(
					AppendItem = obj[count] --copy it
					deleteItem obj count --delete original in array
					append obj AppendItem --append to end of array
					--objects without parents need to be transformed last to stop xform/rotation issues for their children
				)
				else
				(
					count = count + 1 --check next object in array if first is a child
				)
			)
			
			for items in obj do --for each items selected
			(
				append parentArray items.parent --adds the parent of an object to the parrent array (adds undefined if no parent)
				items.parent = undefined --sets parent to undefined (deletes parent links in heiracy)
				ResetXForm(items) --reset xform
				collapseStack(items) --collapse modifier stack
				rotate items SetRotation --rotates item -90 0 0 for unity
				ResetXForm(items) --reset xform and collapse stack again to "bake in" applied rotation
				collapseStack(items)
				rotate items ResetRotation --rotates item back to original place without baking in rotation (for unity -90 x problem)
			)
			
			for items in obj do
			(
				items.parent = ParentArray[i] --assigns original parent back to object from parent array
				i = i + 1
			)
		)
	)
	
	on CheckCombined changed theState do
	(
		FileNameInput.readOnly = NOT FileNameInput.readOnly --toggles whether file name input is ready only or not based on whether check combined (export as single file) is ticked.

	)
	
	on CheckPreserveMat changed theState do
	(
		preserveMat = NOT preserveMat --toggles whether the variable preserveMat is true or false (used in btnExport for whether to change default mat or not)
		print preserveMat
	)
	
	on CheckCleanUp changed theState do
	(
		if CheckCleanUp.checked == true and ToggleWarnings == false then --if toggle warnings is OFF, this message will be displayed
		(
			messageBox "Running clean up tools before export will include resetting Xform. Resetting Xform of objects whose parents have parents can have undesired affects. Single level parent and child objects will work normally." title: "Warning"
		)
	)
	
	on CheckWarnings changed theState do --toggles whether warning messages should be displayed
	(
		ToggleWarnings = NOT ToggleWarnings
	)
	
	on btnExport pressed do
	(
		case ExportType.state of --sets the name of the export state radio buttons
		(
			1: "Unity"
			2: "UE4"
			3: "None"
		)
		if ExportType.state == 1 and ToggleWarnings == false then --if warning messages are turned ON, and you're attempting to export with unity settings, this warning message is displayed:
		(
			InputValue = okCancelBox "Exporting for Unity will include running Unity Reset, which will reset Xform. Resetting Xform of objects whose parents have parents can have undesired affects. Single level parent and child objects will work normally." title: "Warning"						
		) --returns "ok" or "cancel"
		else
		(
			InputValue = #ok --if warnings are OFF, "ok" is automatically set
		)
		if InputValue == #ok then --if not cancelled, proceeds as normal
		(
			obj=selection as Array
			gotDirectoryOnce=
			if obj.count==0 then (messageBox "Select Objects")
			else
			(
				for items in obj do --for all selected options
				(
					if CheckCleanUp.checked== true then --run clean up tools
					(
						if preserveMat == false then
						(
							defaultMat()
						)
						
						FnXform()
						
						if CheckCombined.checked ==false then --if not exporting as single file, resets all object pivots
						(
							items.pos=[0,0,0]
						)
					)
					
					if ExportType.state == 1 then --if exporting for Unity, runs unity reset process
					(
						UnityReset()
					)
					
					if CheckCombined.checked != true then --if not exporting as single file,
					(
						select items
						newFileName = items.name
						
						if newDirectory!=undefined  and CheckDirectory.checked!=true or gotDirectoryOnce==true then --if a directory is set and you don't want to change it, or it has already been changed once during the first loop
						(
							if ExportType.state == 2 then --if exporting for UE4, adds "SM" to file name (static mesh)
							(
								completeFilePath = (newDirectory + "/" + "SM_" + newFileName)
							)
							else
							(
								completeFilePath = (newDirectory + "/" + newFileName)
							)
							
							if CheckPanel.checked == true then --if show export settings is checked, does not hide prompts,
								(
									exportFile completeFilePath selectedOnly:true using:FBXEXP
								)
							else --otherwise hides prompt
								(
									exportFile completeFilePath #noPrompt selectedOnly:true using:FBXEXP
								)
						)
						if newDirectory==undefined or CheckDirectory.checked==true and gotDirectoryOnce!=true then --if there isn't a directory set, or you want to change it and it hasn't been changed in the first loop
						(	
							newDirectory = getSavePath() --getting a new directory path if one isn't set
							if newDirectory==undefined then stop else
							(
								completeFilePath = (newDirectory + "/" + newFileName)
								if CheckPanel.checked == true then
									(
										exportFile completeFilePath selectedOnly:true using:FBXEXP --shows export panels
									)
								else
									(
										exportFile completeFilePath #noPrompt selectedOnly:true using:FBXEXP -- doesn't show export panels
									)
							)
							gotDirectoryOnce = true --set gotDirectoryOnce to true to stop the loop asking for a new directory for every object in the array
						)
						
					)
					else --if exporting as single file
					(
						if FileNameInput.text !="" then --if file name input text box is not blank
						(
							newFileName = FileNameInput.text --file name is text box input
						)
						else
						(
							newFileName = obj[1].name --else file name is called whatever object is at the start of the selection array
						)
						
						if newDirectory!=undefined and CheckDirectory.checked!=true then --if the directory is set and you don't want to change it
						(
							if ExportType.state == 2 then 
							(
								completeFilePath = (newDirectory + "/" + "SM_" + newFileName) --for ue4
							)
							else
							(
								completeFilePath = (newDirectory + "/" + newFileName)
							)
								
							if CheckPanel.checked == true then --if you want to see the export panel
								(
									exportFile completeFilePath selectedOnly:true using:FBXEXP --displays it
								)
							else
								(
									exportFile completeFilePath #noPrompt selectedOnly:true using:FBXEXP --otherwise prompts are hidden
								)
						)
						else
						(	
							newDirectory = getSavePath()
							if newDirectory==undefined then stop else
							(
								completeFilePath = (newDirectory + "/" + newFileName)
								if CheckPanel.checked == true then
									(
										exportFile completeFilePath selectedOnly:true using:FBXEXP
									)
								else
									(
										exportFile completeFilePath #noPrompt selectedOnly:true using:FBXEXP
									)
							)
						)
					exit --exits the for each loop when exporting as single file
					)
					
				)
				
			)
		)	
		
	)
	
	on btnXform pressed do -- reset xform button
	(
		if ToggleWarnings == false then --if warnings are turned ON, displays warning message:
		(
			InputValue = okCancelBox "Resetting Xform of objects whose parents have parents can have undesired affects. Single level parent and child objects will work normally." title: "Warning"
		)
		else
		(
			InputValue = #ok --if warnings are turned off, automatically ok
		)
		if InputValue == #ok then --unless cancelled, proceeds as normal
		(
			FnXform()
		)
	)
	
	on btnUnityReset pressed do -- unity reset button
	(
		if ToggleWarnings == false then --if warnings are turned on, displays warning message
		(
			InputValue = okCancelBox "Unity Reset will include resetting Xform. Resetting Xform of objects whose parents have parents can have undesired affects. Single level parent and child objects will work normally." title: "Warning"
		)
		else
		(
			InputValue = #ok --if warnings are turned off, automatically ok
		)
		if InputValue == #ok then --proceeds unless cancelled
		(
			UnityReset()
		)
	)
		
	
	on btnTop pressed do --pivot to top
	(
		obj=selection as array
		if obj.count==0 then (messageBox "Select Objects")
		else
		(
		for items in obj do
			(
				items.pivot = [items.center.x,items.center.y,items.max.z]
				items.pos=[0,0,0]		
			)
		)
	)
	on btnCenter pressed do --pivot to centre
	(
		obj=selection as array
		if obj.count==0 then (messageBox "Select Objects")
		else
		(

		for items in obj do
			(
				items.pivot = [items.center.x,items.center.y,items.center.z]
				items.pos=[0,0,0] 
			)
		)

	)
	on btnBottom pressed do --pivot to bottom
	(
		obj=selection as array
		if obj.count==0 then (messageBox "Select Objects")
		else
		(
			for items in obj do
			(
				items.pivot = [items.center.x,items.center.y,items.min.z]
				items.pos=[0,0,0] 
			)
		)
	 
	)

	
	on btnDefaultMat pressed do -- set default material
	(
		defaultMat()
	)
	
	
	on btnCollapse pressed do --collapse stack
	(
		obj=selection as Array
		if obj.count==0 then (messageBox "Select Objects")
		else
		(
			for items in obj do
			(
				collapseStack(items)
				convertToPoly(items)
			)
		)
	)
	
	on btnCombine pressed do --combine selected
	(
		obj=selection as array
		if obj.count==0 then (messageBox "Select Objects")
		else
		(
			max select invert --inverts the selection
			freeze selection --freezes it
			CombineElements()
			select $* --select everything
			unfreeze selection --unfreezes everything
			deselect $* --unselects everything
		)
	)
	
	on btnDetach pressed do --detach elements (didn't write this obvs)
	(
		/*
		Detach Elements v.1.0
		Author : Anubis [project3d.narod.ru]
		*/
		if Detach2Elements != undefined do
			if classOf Detach2Elements == RolloutClass do
				destroyDialog Detach2Elements
		rollout Detach2Elements "Detach Elements"
		(
			--// Top level Locals
			local srcObjs = #() -- source objs
			local tmpObjs = #() -- temporary
			local endObjs = #() -- for conv2Mesh
			local eleGroups = #() -- for UnGrouping
			--// Functions
			fn DetachToElements obj cPivot &endObjs num:1 = (
				while obj.getNumFaces() != 0 do (
					polyop.setFaceSelection obj #{1}
					obj.selectElement()
					ele = polyop.getFaceSelection obj
					newName = (num as string)
					num += 1 -- pump up counter
					polyop.detachFaces obj ele asNode:true name:newName
					newObj = getNodeByName newName
					append endObjs newObj
					attachObjects obj newObj
				)
				if cPivot do centerPivot obj.children
			)
			mapped fn renameChildren ch = (
				ch.name = ch.parent.name + ch.name
			)
			--// UI
			group "Base Options"
			(
				checkBox keepSource "Keep Source Objects" checked:true
				checkBox UndoOn "Enable Undo" checked:false --enabled:false
			)
			group "New Objects"
			(
				checkBox outMesh "Convert to Mesh" checked:false
				checkBox isGroup "Group by Source" checked:false
				checkBox cPivot "Center Pivot" checked:false
			)
			group ">>>"
			(
				button detach "Detach" width:140
				label feed "..."
				progressbar progBar color:green
			)
			--// this function must be here! (ie after UI def.)
			fn runEntirely = (
				feed.text = "Detaching..."
				local total = (tmpObjs.count as string) -- total objects
				for i = 1 to tmpObjs.count do (
					feed.text = "Detaching... " + (i as string) + "/" + total -- progress
					DetachToElements tmpObjs[i] cPivot.state endObjs
					grp = group tmpObjs[i].children name:(srcObjs[i].name + "_Elements")
					append eleGroups grp -- for UnGrouping ...
					attachObjects srcObjs[i] grp move:false -- link G to source obj.
					renameChildren grp.children -- rename
					progBar.value = 100. * i / tmpObjs.count -- % progress
				)
				progBar.value = 0 -- reset progressbar
				feed.text = "Finalize..."
				eleGroups = for g in eleGroups where isValidNode g collect g -- important!
				if not isGroup.state do ( -- if you rid of groups...
					if not keepSource.state do ( -- and original objs deleted...
						local n = 1 -- get for progressBar
						for g in eleGroups do ( -- to preserve hierarchy...
							holder = point pos:g.pos name:g.name
							g.parent = holder -- replace GroupHead with Point.
							progBar.value = 100. * n / eleGroups.count -- % progress
							n += 1 -- pump up counter
						)
					)
					progBar.value = 0 -- reset progressbar
					ungroup eleGroups -- now ungroup all at once
				)
				if not keepSource.state do (delete srcObjs)
			)
			--// Events
			on detach pressed do
			(
				feed.text = "Initialize..."
				--// filter selection
				srcObjs = for i in selection where canConvertTo i Editable_Poly collect i
				-- save your time
				if srcObjs.count == 0 then (
					feed.text = "* Nothing to proceed *"
				)
				else ( --// Runtime...
					disableSceneRedraw()
					feed.text = "Preparation..."
					max create mode
					setWaitCursor() -------------------
					TimeStart = timestamp()
					numObjs = objects.count
					snapshot srcObjs -- make copies...
					tmpObjs = ( -- and collect 'em
						for i = (numObjs + 1) to objects.count collect objects[i]
					)
					convertTo tmpObjs Editable_Poly
					--// the "core" in Undo context
					with undo "Detach" UndoOn.state ( runEntirely() )
					delete tmpObjs -- KEEP this Out Off Undo context !!!
					---------------------
					endObjs = for i in endObjs where isValidNode i collect i -- important!
					if outMesh.state do convertToMesh endObjs
					select endObjs
					feed.text = "Done!"
					TimeEnd = (timestamp() - TimeStart) / 1000.
					setArrowCursor() --------------------
					enableSceneRedraw()
					redrawViews()
					format "Time:\t%sec.\n" TimeEnd
				) -- end (Runtime)
			) -- end (on detach pressed)
		) -- end of rollout
		createDialog Detach2Elements
	)
)
CreateDialog exporttools
cui.registerDialogBar exporttools
cui.dockDialogBar exporttools #cui_dock_left



