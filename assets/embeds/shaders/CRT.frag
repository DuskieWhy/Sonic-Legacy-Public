#pragma header

uniform float warp;// simulate curvature of CRT monitor
void main()
{
    // squared distance from center
    vec2 uv=(openfl_TextureCoordv*openfl_TextureSize)/openfl_TextureSize.xy;
    vec2 dc=abs(.5-uv)*abs(.5-uv);
    
    // warp the fragment coordinates
    uv.x-=.5;uv.x*=1.+(dc.y*(.3*warp));uv.x+=.5;
    uv.y-=.5;uv.y*=1.+(dc.x*(.4*warp));uv.y+=.5;
    
    // sample inside boundaries, otherwise set to black
    if(uv.y>1.||uv.x<0.||uv.x>1.||uv.y<0.)
    gl_FragColor=vec4(0.,0.,0.,1.);
    else
    {
        gl_FragColor=flixel_texture2D(bitmap,uv);
    }
}