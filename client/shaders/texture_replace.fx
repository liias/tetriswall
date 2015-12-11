texture tetrisTexture;


float3x3 getTextureTransform() {
    return float3x3(
    				0, -1, 0, // translation
                    1, 0, 0, // rotation about the center point
                    0, 0, 1
                    );
}


technique TextureReplace {
	pass Pass0 {
		// Replace texture
		Texture[0] = tetrisTexture;

		// Rotate texture 90 degrees, 
		// see http://www.euclideanspace.com/maths/algebra/matrix/orthogonal/rotation/

        TextureTransform[0] = getTextureTransform();
        TextureTransformFlags[0] = Count2;

	}
}