function Local2World mWorld vec = (
	vec * mWorld
)


function World2Local mWorld vec = (
	vec * (inverse mWorld)
)


function EP_VertexLocalPos target idx = (
	local wpos = polyop.getVert target idx
	local lpos = World2Local target.transform wpos
	lpos
)


function EP_VertexWorldPos target idx = (
	local wpos = polyop.getVert target idx
	wpos
)


function LWF_BBoxGen_GenFromTargetVerts target verts expand = (
	if verts.count == 0 do (
		return undefined
	)
	local posmin = EP_VertexLocalPos target verts[1]
	local posmax = EP_VertexLocalPos target verts[1]
	for i in verts do (
		local pos = EP_VertexLocalPos target i
		if pos.x < posmin.x do posmin.x = pos.x
		if pos.x > posmax.x do posmax.x = pos.x
		if pos.y < posmin.y do posmin.y = pos.y
		if pos.y > posmax.y do posmax.y = pos.y
		if pos.z < posmin.z do posmin.z = pos.z
		if pos.z > posmax.z do posmax.z = pos.z
	)
	local diff = posmax - posmin
	local b = box()
	b.width  = diff.x + expand
	b.height = diff.z + expand
	b.length = diff.y + expand
	b.pos.z -= b.height / 2.0
	b.pivot = [0.0, 0.0, 0.0]
	b.transform = target.transform
	targetcenter = Local2World target.transform ((posmax - posmin) / 2.0 + posmin)
	vec = targetcenter - target.pivot
	b.pos += vec
	b.pivot = target.pivot
	return b
)


function LWF_BBoxGen_Gen \
	target \
	mode:1 \
	expand:0.0 \
	select_after_gen:false \
	rename:true \
	rename_format:"{prefix}_{target}_{suffix}{idx}" \
	rename_prefix:"BBox" \
	rename_suffix:"" \
	rename_idx_start:0 \
	rename_idx_len:3 \
	rename_target_name_proc:"target.name" \
	rename_allow_duplicate:false \
	auto_parent: false\
	auto_parent_proc:"target" \
	= (

	-- Geometry Check
	if not isKindOf target Editable_Poly do return "Mesh should be Editable_Poly"

	local allrets = #()

	-- Object Mode
	if mode == 1 then (
		try(
			local ret = LWF_BBoxGen_GenFromTargetVerts target (for i = 1 to (polyop.getNumVerts target) collect i) expand
			if ret != undefined do append allrets ret
		) catch (return (getCurrentException()))
	)

	-- Elements Mode
	else if mode == 2 then (
		local elefaces = #()
		local eleverts = #()
		local allfaces = (for i = 1 to (polyop.getNumFaces target) collect i) as BitArray
		for f in allfaces do (
			local pass = false
			for ef in elefaces do (
				if (findItem ef f) != 0 do (
					pass = true
					exit()
				)
			)
			if pass do continue
			local buff = polyop.getElementsUsingFace target f
			append elefaces buff
		)

		 for ef in elefaces do (
			local buff = #{}
			for f in ef do (
				buff += polyop.getVertsUsingFace target f
			)
			append eleverts buff
		 )
		for ev in eleverts do (
			try (
				local ret = LWF_BBoxGen_GenFromTargetVerts target (ev as array) expand
				if ret != undefined do append allrets ret
			)
			catch (return (getCurrentException()))
		)
		if select_after_gen do select allrets
	)

	-- Selected Face Mode
	else if mode == 3 then (
		if target.selectedFaces.count < 1 do (
			return "At least 1 face should be selected"
		)
		local buff = #{}
		for fidx in target.selectedFaces do (
			buff += polyop.getVertsUsingFace target fidx
		)
		try(
			local ret = LWF_BBoxGen_GenFromTargetVerts target (buff as array) expand
			if ret != undefined do append allrets ret
		) catch (return (getCurrentException()))
	)
	else ()

	for r in allrets do (
		r.wirecolor = color (random 0 255) (random 0 255) (random 0 255)
	)

	-- Rename
	if rename do (
		local idx = rename_idx_start
		for b in allrets do (
			local cand_name = rename_format
			cand_name = substituteString cand_name "{prefix}" rename_prefix
			cand_name = substituteString cand_name "{suffix}" rename_suffix
			try (
				local func = execute ("function __bbox_gen_rename_target_name_proc target = (" + rename_target_name_proc + ")")
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
			b.name = cand_name
		)
	)

	-- Parent
	if auto_parent do (
		try (
			local func = execute ("function __bbox_gen_auto_parent_proc target = (" + auto_parent_proc + ")")
			for r in allrets do (
				r.parent = func target
			)
		) catch (return getCurrentException())
	)

	-- Select
	if select_after_gen do select allrets

	return undefined
)


rollout LWRLT_BBoxGen_Select "Select" (
	checkbox ckbSelect "Select After Generated" tooltip:"Select generated BBox after generation"

	on LWRLT_BBoxGen_Select open do (
		ckbSelect.checked = true
	)
)


rollout LWRLT_BBoxGen_Parent "Parent" (
	checkbox ckbAutoParent "Auto Parent" tooltip:"Automatically reparent"
	edittext etAutoParentProc "Parent Proc" enabled:false tooltip:"Reparent MAXScript expression which evaluates a node to be parent candidate"

	function refresh = (
		etAutoParentProc.enabled = ckbAutoParent.checked
	)

	on LWRLT_BBoxGen_Parent open do (
		ckbAutoParent.checked = false
		etAutoParentProc.text = "target"
		refresh()
	)

	on ckbAutoParent changed state do (
		refresh()
	)
)


rollout LWRLT_BBoxGen_Rename "Rename" (
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

	on LWRLT_BBoxGen_Rename open do (
		ckbRename.checked = false
		ckbRenameAllowDup.checked = false
		etRenameFormat.text = "{prefix}_{target}_{suffix}{idx}"
		etRenamePrefix.text = "BBox"
		etRenameSuffix.text = "Gen"
		etRenameTargetProc.text = "target.name"
		spnRenameSIndex.value = 0
		spnRenameWIndex.value = 3
		refresh()
	)

	on ckbRename changed state do (
		refresh()
	)
)


rollout LWRLT_BBoxGen_Other "Other" (
	spinner spnExpand "Expand" width:245 height:20 range:[-9999999, 9999999, 0] type:#float align:#left tooltip:"Expand BBox size"

	on LWRLT_BBoxGen_Other open do (
		spnExpand.value = 0.0
	)
)


rollout LWRLT_BBoxGen_Gen "Generate" (

	button btnGenFromObj "Generate from Objects" width:230 height:40 tooltip:"Generate from each selected object's bounding box"
	button btnGenFromEle "Generate from All Elements" width:230 height:40 tooltip:"Auto generate from all elements' bounding box of objects"
	button btnGenFromSel "Generate from Selected Faces" width:230 height:40 tooltip:"Generate from selected faces' bounding box"

	on btnGenFromObj pressed do (
		undo on (
			for o in (selection as array) do (
				local ret = LWF_BBoxGen_Gen o \
								mode:1 \
								expand:                  LWRLT_BBoxGen_Other.spnExpand.value \
								select_after_gen:        LWRLT_BBoxGen_Select.ckbSelect.checked \
								rename:                  LWRLT_BBoxGen_Rename.ckbRename.checked \
								rename_format:           LWRLT_BBoxGen_Rename.etRenameFormat.text \
								rename_prefix:           LWRLT_BBoxGen_Rename.etRenamePrefix.text \
								rename_suffix:           LWRLT_BBoxGen_Rename.etRenameSuffix.text \
								rename_idx_start:        LWRLT_BBoxGen_Rename.spnRenameSIndex.value \
								rename_idx_len:          LWRLT_BBoxGen_Rename.spnRenameWIndex.value \
								rename_target_name_proc: LWRLT_BBoxGen_Rename.etRenameTargetProc.text \
								rename_allow_duplicate:  LWRLT_BBoxGen_Rename.ckbRenameAllowDup.checked \
								auto_parent:             LWRLT_BBoxGen_Parent.ckbAutoParent.checked \
								auto_parent_proc:        LWRLT_BBoxGen_Parent.etAutoParentProc.text \
				if ret != undefined do (
					messageBox ret
					messageBox ("Failed generating BBox for :" + (o as String))
				)
			)
		)
		redrawViews()
	)

	on btnGenFromEle pressed do (
		undo on (
			for o in (selection as array) do (
				local ret = LWF_BBoxGen_Gen o \
								mode:2 \
								expand:                  LWRLT_BBoxGen_Other.spnExpand.value \
								select_after_gen:        LWRLT_BBoxGen_Select.ckbSelect.checked \
								rename:                  LWRLT_BBoxGen_Rename.ckbRename.checked \
								rename_format:           LWRLT_BBoxGen_Rename.etRenameFormat.text \
								rename_prefix:           LWRLT_BBoxGen_Rename.etRenamePrefix.text \
								rename_suffix:           LWRLT_BBoxGen_Rename.etRenameSuffix.text \
								rename_idx_start:        LWRLT_BBoxGen_Rename.spnRenameSIndex.value \
								rename_idx_len:          LWRLT_BBoxGen_Rename.spnRenameWIndex.value \
								rename_target_name_proc: LWRLT_BBoxGen_Rename.etRenameTargetProc.text \
								rename_allow_duplicate:  LWRLT_BBoxGen_Rename.ckbRenameAllowDup.checked \
								auto_parent:             LWRLT_BBoxGen_Parent.ckbAutoParent.checked \
								auto_parent_proc:        LWRLT_BBoxGen_Parent.etAutoParentProc.text \
				if ret != undefined do (
					messageBox ret
					messageBox ("Failed generating BBox for :" + (o as String))
				)
			)
		)
		redrawViews()
	)

	on btnGenFromSel pressed do (
		undo on (
			for o in (selection as array) do (
				local ret = LWF_BBoxGen_Gen o \
								mode:3 \
								expand:                  LWRLT_BBoxGen_Other.spnExpand.value \
								select_after_gen:        LWRLT_BBoxGen_Select.ckbSelect.checked \
								rename:                  LWRLT_BBoxGen_Rename.ckbRename.checked \
								rename_format:           LWRLT_BBoxGen_Rename.etRenameFormat.text \
								rename_prefix:           LWRLT_BBoxGen_Rename.etRenamePrefix.text \
								rename_suffix:           LWRLT_BBoxGen_Rename.etRenameSuffix.text \
								rename_idx_start:        LWRLT_BBoxGen_Rename.spnRenameSIndex.value \
								rename_idx_len:          LWRLT_BBoxGen_Rename.spnRenameWIndex.value \
								rename_target_name_proc: LWRLT_BBoxGen_Rename.etRenameTargetProc.text \
								rename_allow_duplicate:  LWRLT_BBoxGen_Rename.ckbRenameAllowDup.checked \
								auto_parent:             LWRLT_BBoxGen_Parent.ckbAutoParent.checked \
								auto_parent_proc:        LWRLT_BBoxGen_Parent.etAutoParentProc.text \
				if ret != undefined do (
					messageBox ret
					messageBox ("Failed generating BBox for :" + (o as String))
				)
			)
		)
		redrawViews()
	)

)


try (closeRolloutFloater LWRLTF_BBoxGen_Panel) catch()
LWRLTF_BBoxGen_Panel = newRolloutFloater "BBox Gen 0.0.1" 250 400
addRollout LWRLT_BBoxGen_Gen    LWRLTF_BBoxGen_Panel rolledup:false
addRollout LWRLT_BBoxGen_Select LWRLTF_BBoxGen_Panel rolledup:true
addRollout LWRLT_BBoxGen_Parent LWRLTF_BBoxGen_Panel rolledup:true
addRollout LWRLT_BBoxGen_Rename LWRLTF_BBoxGen_Panel rolledup:true
addRollout LWRLT_BBoxGen_Other  LWRLTF_BBoxGen_Panel rolledup:true
