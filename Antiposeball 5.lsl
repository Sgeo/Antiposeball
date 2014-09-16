list gAnimList;
vector wantedPos; //Without adjustment
rotation wantedRot; //Shouldn't need adjustment
key sitter; //Used in the poser
integer satOn = FALSE; //Used in the poser

startAnims()
{
    if(!(llGetPermissions() & PERMISSION_TRIGGER_ANIMATION)) return;
    integer aListLen = llGetListLength(gAnimList);
    if(aListLen==0) return;
    llStopAnimation("sit");
    integer i;
    for(i=0; i<aListLen; i+=1)
    {
        llStartAnimation(llList2String(gAnimList, i));
    }
}

stopAnims()
{
    if(!(llGetPermissions() & PERMISSION_TRIGGER_ANIMATION)) return;
    integer aListLen = llGetListLength(gAnimList);
    integer i;
    for(i=0; i<aListLen; i+=1)
    {
        llStopAnimation(llList2String(gAnimList, i));
    }
}

default
{
    state_entry()
    {
        llListen(300, "", llGetOwner(), "");
        llOwnerSay("If you find this script useful, please consider sending a donation to Sgeo Comet. Your support is greatly appreciated.");
        llOwnerSay("To use:");
        llOwnerSay("First sit down on a different object that you can move around");
        llOwnerSay("Then say either:");
        llOwnerSay("/300 none");
        llOwnerSay("If you don't want a special animation");
        llOwnerSay("/300 anim1, anim2");
        llOwnerSay("For animations");
    }

    listen(integer chan, string name, key id, string msg)
    {
        if(msg=="none")
        {
            state waiting;
        }
        gAnimList = llParseString2List(msg, [",", ", "], []);
        state setanims;
    }
}

state setanims
{
    state_entry()
    {
        llRequestPermissions(llGetOwner(), PERMISSION_TRIGGER_ANIMATION);
    }
    
    run_time_permissions(integer perm)
    {
        if(!(perm & PERMISSION_TRIGGER_ANIMATION))
        {
            llResetScript();
        }
        startAnims();
        state waiting;
    }
}

state waiting
{
    state_entry()
    {
        llOwnerSay("Say /300 done when done!");
        llListen(300, "", llGetOwner(), "done");
    }
    listen(integer chan, string name, key id, string msg)
    {
        llSensor("", id, AGENT, 96., TWO_PI);
    }
    sensor(integer num_detected)
    {
        wantedPos = llDetectedPos(0);
        wantedRot = llDetectedRot(0);
        //llSitTarget(wantedPos / llGetPos(), wantedRot / llGetRot());
        llSitTarget((wantedPos - llGetPos()) / llGetRot(), wantedRot / llGetRot());
        stopAnims();
        state adjusting;
        //state finishing;
    }
}

state adjusting
{
    state_entry()
    {
        llOwnerSay("Ok, we need to adjust one minor thing..");
        llOwnerSay("Please sit down on me.");
    }
    changed(integer change)
    {
        if(!(change & CHANGED_LINK)) return;
        key av = llAvatarOnSitTarget();
        if(av==NULL_KEY) return;
        if(av!=llGetOwner())
        {
            llUnSit(av);
            return;
        }
        llRequestPermissions(av, PERMISSION_TRIGGER_ANIMATION);
    }
    run_time_permissions(integer perm)
    {
        if(!(perm & PERMISSION_TRIGGER_ANIMATION)) return;
        startAnims();
        llSensor("", llGetOwner(), AGENT, 96., TWO_PI);
    }
    sensor(integer num_detected)
    {
        vector pos = llDetectedPos(0);
        vector discrep = pos - wantedPos;
        llSitTarget((wantedPos - llGetPos() - discrep) / llGetRot(), wantedRot / llGetRot());
    //llSitTarget((wantedPos - llGetPos()) / llGetRot(), wantedRot / llGetRot());
        llOwnerSay("llSitTarget(" + (string)((wantedPos - llGetPos() - discrep) / llGetRot()) + ", " + (string)(wantedRot / llGetRot()) + ");");
        state finishing;
    }
}
        
state finishing
{
    state_entry()
    {
        if(llAvatarOnSitTarget()!=NULL_KEY)
        {
            llRequestPermissions(llAvatarOnSitTarget(), PERMISSION_TRIGGER_ANIMATION);
            llUnSit(llAvatarOnSitTarget());
            state poser;
        }
       // state poser;
    }
    run_time_permissions(integer perm)
    {
        if(perm & PERMISSION_TRIGGER_ANIMATION)
        {
            stopAnims();
        }
        llUnSit(llAvatarOnSitTarget());
        state poser;
    }
}

state poser
{
    state_entry()
    {
        llOwnerSay("We're done!");
        if(llGetListLength(gAnimList)==0)
        {
            llRemoveInventory(llGetScriptName());
        }
    }
    changed(integer change)
    {
        if(!(change & CHANGED_LINK)) return;
        if(llAvatarOnSitTarget()!=NULL_KEY && !satOn)
        {
            llRequestPermissions(llAvatarOnSitTarget(), PERMISSION_TRIGGER_ANIMATION);
            satOn = TRUE;
            return;       
        }
        if(llAvatarOnSitTarget()==NULL_KEY && satOn)
        {
            //llRequestPermissions(sitter, PERMISSION_TRIGGER_ANIMATION);
            satOn = FALSE;
            return;
        }
    }
    run_time_permissions(integer perm)
    {
        if(llAvatarOnSitTarget()!=NULL_KEY)
        {
            startAnims();
            sitter = llAvatarOnSitTarget();
            return;
        }
        if(satOn)
        {
            stopAnims();
            sitter=NULL_KEY;
            return;
        }
    }
}