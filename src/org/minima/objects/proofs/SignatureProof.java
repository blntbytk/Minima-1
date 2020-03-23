package org.minima.objects.proofs;

import java.io.DataInputStream;
import java.io.DataOutputStream;
import java.io.IOException;

import org.minima.objects.Proof;
import org.minima.objects.base.MiniData;
import org.minima.objects.base.MiniHash;
import org.minima.utils.json.JSONObject;

public class SignatureProof extends Proof {

	/**
	 * The actual signature from the MiniHash data..
	 */
	MiniData mSignature;
	
	private SignatureProof() {}
	
	public SignatureProof(MiniHash mPublicKey, MiniData zSignature) {
		super();
		
		setData(mPublicKey);
		
		mSignature = zSignature;
	}
	
	public MiniData getSignature(){
		return mSignature;
	}
	
	@Override
	public JSONObject toJSON() {
		JSONObject json = new JSONObject();
		json.put("signature", mSignature.to0xString());
		json.put("proof", super.toJSON());
		return json;
	}
	
	@Override
	public void writeDataStream(DataOutputStream zOut) throws IOException {
		mSignature.writeDataStream(zOut);
		super.writeDataStream(zOut);
	}

	@Override
	public void readDataStream(DataInputStream zIn) throws IOException {
		mSignature = MiniData.ReadFromStream(zIn);
		super.readDataStream(zIn);
	}
	
	public static SignatureProof ReadFromStream(DataInputStream zIn){
		SignatureProof sigproof = new SignatureProof();
		
		try {
			sigproof.readDataStream(zIn);
		} catch (IOException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
		
		return sigproof;
	}
}