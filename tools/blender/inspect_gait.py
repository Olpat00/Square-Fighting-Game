"""Measure authored stance-foot drift at nominal travel; validate real Blender bone transforms."""
import bpy,json,sys
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
ids=sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else ['f01_clutch','f04_deadfall','f05_fine_print','source_damion','source_will']
report=[]
for fid in ids:
    bpy.ops.wm.open_mainfile(filepath=str(ROOT/'source_art/characters'/fid/(fid+'.blend')))
    rig=bpy.data.objects['FighterRig'];checks=[]
    for clip,seconds,stance,travel in [('run',.62,.4,2.0),('walk',1.05,.6,1.0)]:
        rig.animation_data.action=bpy.data.actions[clip]
        seconds=(rig.animation_data.action.frame_range[1]-rig.animation_data.action.frame_range[0])/60
        for side,start in [('L',0),('R',.5)]:
            points=[];rest=rig.data.bones['foot.'+side].head_local.z
            for i in range(1,8):
                phase=start+stance*i/8
                time=(phase%1)*seconds*60+1
                bpy.context.scene.frame_set(int(time),subframe=time%1)
                co=rig.pose.bones['foot.'+side].matrix.translation
                points.append({'phase':phase,'ankle_z':co.z,'travel_compensated_x':travel*phase-co.y})
            drift=max(p['travel_compensated_x'] for p in points)-min(p['travel_compensated_x'] for p in points)
            error=max(abs(p['ankle_z']-rest) for p in points)
            checks.append({'clip':clip,'foot':side,'stance_drift_m':drift,'ankle_height_error_m':error,'samples':points,'pass':drift<.045 and error<.04})
    report.append({'id':fid,'checks':checks,'pass':all(c['pass'] for c in checks)})
    print('GAIT',fid,'PASS' if report[-1]['pass'] else 'FAIL',[(c['clip'],c['foot'],round(c['stance_drift_m'],4),round(c['ankle_height_error_m'],4)) for c in checks],flush=True)
(ROOT/'evidence/characters/gait_validation.json').write_text(json.dumps(report,indent=2))
