package com.boldesi.tamil_via_hindi

import com.google.android.play.integrity.IntegrityManagerFactory
import com.google.android.play.integrity.IntegrityTokenRequest
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
	private val channelName = "play_integrity"

	override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
		super.configureFlutterEngine(flutterEngine)

		MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
			.setMethodCallHandler { call, result ->
				if (call.method != "requestIntegrityToken") {
					result.notImplemented()
					return@setMethodCallHandler
				}

				val projectNumber = call.argument<Long>("cloudProjectNumber")
				val nonce = call.argument<String>("nonce")

				if (projectNumber == null || nonce.isNullOrBlank()) {
					result.error("INVALID_ARGS", "Missing project number or nonce", null)
					return@setMethodCallHandler
				}

				val integrityManager = IntegrityManagerFactory.create(applicationContext)
				val request = IntegrityTokenRequest.builder()
					.setCloudProjectNumber(projectNumber)
					.setNonce(nonce)
					.build()

				integrityManager.requestIntegrityToken(request)
					.addOnSuccessListener { response ->
						result.success(response.token())
					}
					.addOnFailureListener { e ->
						result.error("INTEGRITY_ERROR", e.message, null)
					}
			}
	}
}
