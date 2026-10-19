"""Animator helpers. Run in Blender's scripting workspace after opening curated.blend.

snap_controls('hands'|'feet'|'body') positions targets at the current evaluated
pose before enabling them, so switching FK to IK never jumps to the rest pose.
Control animation is baked by the ordinary protected glTF exporter.
"""
import bpy


def snap_controls(group='hands',rig=None):
    rig=rig or bpy.data.objects['FighterRig']
    bpy.context.view_layer.update()
    if group in ['hands','feet']:
        limb='hand' if group=='hands' else 'foot'
        for side in ['L','R']:
            target=rig.pose.bones['CTRL_'+limb+'.'+side]
            target.matrix=rig.pose.bones[limb+'.'+side].matrix.copy()
        rig['ik_'+group]=1.0
    elif group=='body':
        for name in ['pelvis','spine','chest']:
            rig.pose.bones['CTRL_'+name].matrix=rig.pose.bones[name].matrix.copy()
        rig['body_controls']=1.0
    else:raise ValueError('Expected hands, feet or body')
    bpy.context.view_layer.update()
    return rig


def key_controls(group='hands',frame=None,rig=None):
    rig=rig or bpy.data.objects['FighterRig'];frame=frame or bpy.context.scene.frame_current
    names=['CTRL_'+n for n in ['pelvis','spine','chest']] if group=='body' else ['CTRL_'+('hand' if group=='hands' else 'foot')+'.'+side for side in ['L','R']]
    for name in names:
        bone=rig.pose.bones[name];bone.rotation_mode='QUATERNION'
        bone.keyframe_insert('location',frame=frame,group=name);bone.keyframe_insert('rotation_quaternion',frame=frame,group=name)
    prop='body_controls' if group=='body' else 'ik_'+group
    rig.keyframe_insert('["'+prop+'"]',frame=frame)
