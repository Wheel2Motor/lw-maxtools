function LWF_EPSPlit_DoSplit
	target \
	keepOrg:true \
	select_after_gen:false \
	rename:true \
	rename_format:"{prefix}_{target}_{suffix}{idx}" \
	rename_prefix:"com" \
	rename_suffix:"" \
	rename_target_name_proc:"target.name" \
	rename_allow_duplicate:false \
	rename_idx_start:0 \
	rename_idx_len:3 \
	auto_parent:false \
	auto_parent_proc:"target" \
	= (

	-- Editable_Poly check
	if not (isKindOf target Editable_Poly) do (
		return "Not an Editable Poly"
	)

	local newTarget = copy target
		
	local oldset = #()
	for o in $* do (
		if (isKindOf o Editable_Poly) do (
			append oldset o
		)
	)
	
	while (polyop.getNumFaces newTarget) > 0 do (
		local ele = polyop.getElementsUsingFace newTarget 1
		polyop.detachFaces newTarget ele asNode:true
	)
	delete newTarget
	
	local newset = #()
	for o in $* do (
		if (isKindOf o Editable_Poly) do (
			append newset o
		)
	)
	
	local allrets = #()
	for o in newset do (
		if 0 == (findItem oldset o) do (
			append allrets o
		)
	)
	
	-- Rename
	if rename then (
		for r in allrets do (
			local idx = rename_idx_start
			local cand_name = rename_format
			cand_name = substituteString cand_name "{prefix}" rename_prefix
			cand_name = substituteString cand_name "{suffix}" rename_suffix
			try (
				local func = execute ("function __spsplit_rename_target_name_proc target = (" + rename_target_name_proc + ")")
				cand_name = substituteString cand_name "{target}" (func target)
			) catch (return getCurrentException())
			local idx_str = (idx as String)
			while idx_str.count < rename_idx_len do idx_str = "0" + idx_str
			local temp_name = substituteString cand_name "{idx}" idx_str
			if not rename_allow_duplicate then (
				while true do (
					if (getNodeByName temp_name) == undefined do (
						cand_name = temp_name
						exit()
					)
				idx += 1
				idx_str = idx as String
				while idx_str.count < rename_idx_len do idx_str = "0" + idx_str
					local temp_name = substituteString cand_name "{idx}" idx_str
				)
			)
			else (
				cand_name = temp_name
				idx += 1
			)
			r.name = cand_name
		)
	)
	
	-- Parent
	if auto_parent do (
		try (
			local func = execute ("function __epsplit_auto_parent_proc target = (" + auto_parent_proc + ")")
			for r in allrets do (
				r.parent = func target
			)
		) catch (return getCurrentException())
	)

	-- Select
	if select_after_gen do select allrets

	-- Delete org
	if not keepOrg do delete target

	undefined
)

rollout LWRLT_EPSplit_Select "Select" (
	checkbox ckbSelect "Select After Generated" tooltip:"Select generated BBox after generation"

	on LWRLT_EPSplit_Select open do (
	ckbSelect.checked = true
	)
)


rollout LWRLT_EPSplit_Parent "Parent" (
	checkbox ckbAutoParent "Auto Parent" tooltip:"Automatically reparent"
	edittext etAutoParentProc "Parent Proc" enabled:false tooltip:"Reparent MAXScript expression which evaluates a node to be parent candidate"

	function refresh = (
		etAutoParentProc.enabled = ckbAutoParent.checked
	)

	on LWRLT_EPSplit_Parent open do (
		ckbAutoParent.checked = false
		etAutoParentProc.text = "target.parent"
		refresh()
	)

	on ckbAutoParent changed state do (
		refresh()
	)
)


rollout LWRLT_EPSplit_Rename "Rename" (
	checkbox ckbRename "Rename" tooltip:"Use auto renaming machenism"
	checkbox ckbRenameAllowDup "Allow Duplicate" enabled:false tooltip:"Allow duplicate name in the scene when auto renaming"
	edittext etRenameFormat "Format" enabled:false tooltip:"Renaming format: {prefix} to text in Prefix entry, {suffix} to text in Suffix entry, {target} to Target Proc expression result, {idx} to count index"
	edittext etRenamePrefix "Prefix" enabled:false tooltip:"Renaming replacement for {prefix}"
	edittext etRenameSuffix "Suffix" enabled:false tooltip:"Renaming replacement for {suffix}"
	edittext etRenameTargetProc "Target Proc" enabled:false tooltip:"Renaming replacement for {target}, this is a piece of MAXScript expression which evaluates a string"
	spinner spnRenameSIndex "Index Start" enabled:false range:[0, 9999999, 0] type:#Integer width:245 align:#left tooltip:"Renaming replacement for {idx} which defines the start for idx"
	spinner spnRenameWIndex "Index Width" enabled:false range:[0, 5, 3] type:#Integer width:245 align:#left tooltip:"Renaming {idx} number's string width extent"

	function refresh = (
		ckbRenameAllowDup.enabled = ckbRename.checked
		etRenameFormat.enabled = ckbRename.checked
		etRenamePrefix.enabled = ckbRename.checked
		etRenameSuffix.enabled = ckbRename.checked
		etRenameTargetProc.enabled = ckbRename.checked
		spnRenameSIndex.enabled = ckbRename.checked
		spnRenameWIndex.enabled = ckbRename.checked
	)

	on LWRLT_EPSplit_Rename open do (
		ckbRename.checked = false
		ckbRenameAllowDup.checked = false
		etRenameFormat.text = "{prefix}_{target}_{suffix}{idx}"
		etRenamePrefix.text = "com"
		etRenameSuffix.text = ""
		etRenameTargetProc.text = "target.name"
		spnRenameSIndex.value = 0
		spnRenameWIndex.value = 3
		refresh()
	)

	on ckbRename changed state do (
		refresh()
	)
)


rollout LWRLT_EPSplit_Split "Split" (
	checkbox ckbKeepOrg "Keep Original" checked:true
	button btnSplit "Split" width:230 height:40

	on btnSplit pressed do (
		undo on (
			for o in (selection as array) do (
				local ret = LWF_EPSPlit_DoSplit \
								o \
								keepOrg:                 ckbKeepOrg.checked \
								select_after_gen:        LWRLT_EPSplit_Select.ckbSelect.checked \
								rename:                  LWRLT_EPSplit_Rename.ckbRename.checked \
								rename_format:           LWRLT_EPSplit_Rename.etRenameFormat.text \
								rename_prefix:           LWRLT_EPSplit_Rename.etRenamePrefix.text \
								rename_suffix:           LWRLT_EPSplit_Rename.etRenameSuffix.text \
								rename_target_name_proc: LWRLT_EPSplit_Rename.etRenameTargetProc.text \
								rename_allow_duplicate:  LWRLT_EPSplit_Rename.ckbRenameAllowDup.checked \
								rename_idx_start:        LWRLT_EPSplit_Rename.spnRenameSIndex.value \
								rename_idx_len:          LWRLT_EPSplit_Rename.spnRenameWIndex.value \
								auto_parent:             LWRLT_EPSplit_Parent.ckbAutoParent.checked \
								auto_parent_proc:        LWRLT_EPSplit_Parent.etAutoParentProc.text \
				if ret != undefined do (
					messageBox ret
					messageBox ("Failed spliting: " + (o as String))
				)
			)
		)
	)
)


try (closeRolloutFloater LWRLTF_EPSplit_Panel) catch()
LWRLTF_EPSplit_Panel = newRolloutFloater "EPSplit 0.0.1" 250 250
addRollout LWRLT_EPSplit_Split LWRLTF_EPSplit_Panel rolledup:false
addRollout LWRLT_EPSplit_Select LWRLTF_EPSplit_Panel rolledup:true
addRollout LWRLT_EPSplit_Parent LWRLTF_EPSplit_Panel rolledup:true
addRollout LWRLT_EPSplit_Rename LWRLTF_EPSplit_Panel rolledup:true
