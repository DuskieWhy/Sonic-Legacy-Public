#pragma header
uniform float iTime;
//uniform vec2 pSize;
const vec2 pSize = vec2(1,1);
// Simplex 2D noise
//
vec3 permute(vec3 x){return mod(((x*34.)+1.)*x,289.);}

float snoise(vec2 v){
    const vec4 C=vec4(.211324865405187,.366025403784439,
    -.577350269189626,.024390243902439);
    vec2 i=floor(v+dot(v,C.yy));
    vec2 x0=v-i+dot(i,C.xx);
    vec2 i1;
    i1=(x0.x>x0.y)?vec2(1.,0.):vec2(0.,1.);
    vec4 x12=x0.xyxy+C.xxzz;
    x12.xy-=i1;
    i=mod(i,289.);
    vec3 p=permute(permute(i.y+vec3(0.,i1.y,1.))
    +i.x+vec3(0.,i1.x,1.));
    vec3 m=max(.5-vec3(dot(x0,x0),dot(x12.xy,x12.xy),
    dot(x12.zw,x12.zw)),0.);
    m=m*m;
    m=m*m;
    vec3 x=2.*fract(p*C.www)-1.;
    vec3 h=abs(x)-.5;
    vec3 ox=floor(x+.5);
    vec3 a0=x-ox;
    m*=1.79284291400159-.85373472095314*(a0*a0+h*h);
    vec3 g;
    g.x=a0.x*x0.x+h.x*x0.y;
    g.yz=a0.yz*x12.xz+h.yz*x12.yw;
    return 130.*dot(m,g);
}
float snoise_octaves(vec2 uv,int octaves,float alpha,float beta,vec2 gamma,float delta){
    vec2 pos=uv;
    float t=1.;
    float s=1.;
    vec2 q=gamma;
    float r=0.;
    for(int i=0;i<octaves;i++){
        r+=s*snoise(pos+q);
        pos+=t*uv;
        t*=beta;
        s*=alpha;
        q*=delta;
    }
    return r;
}

void main()
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv=openfl_TextureCoordv;
    
    float dx=.0033*snoise_octaves(uv*1.+iTime*vec2(.00323,.00345),5,.85,-3.,iTime*vec2(-.0323,-.345),1.203);
    float dy=.0023*snoise_octaves(uv*2.+3.+iTime*vec2(-.00323,.00345),5,.85,-3.,iTime*vec2(-.0323,-.345),1.203);
    
    vec2 uv1=uv+vec2(dx,dy);
    vec2 size=openfl_TextureSize.xy/pSize;
    vec4 col=flixel_texture2D(bitmap,floor(uv1*size)/size);
    
    // Output to screen
    gl_FragColor=col;
}