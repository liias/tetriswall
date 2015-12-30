texture tetrisTexture;

float3x3 getTextureTransform() {
    // Rotate texture 90 degrees, 
    // see http://www.euclideanspace.com/maths/algebra/matrix/orthogonal/rotation/
    float3x3 rotated = float3x3(0, -1, 0, // translation
                                1, 0, 0, // rotation about the center point
                                0, 0, 1); // must have 1, or multiplying wouldnt work well
                    
    float3x3 scaled = float3x3(1, 0, 0,
                               0, 2.5, 0,
                               0, 0, 1);
                               
    float3x3 moved = float3x3(1, 0, 0,
                              0, 1, 0,
                              0.21, 0, 1); // move "right" 0.21, but as it's rotated 90 degrees then actually "down"
    
    return mul(moved, mul(rotated, scaled));
}

technique TextureReplace {
	pass Pass0 {
    // Replace texture
		Texture[0] = tetrisTexture;
    
    TextureTransform[0] = getTextureTransform();
    TextureTransformFlags[0] = Count2;
	}
}
