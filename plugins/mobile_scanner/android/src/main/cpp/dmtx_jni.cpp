#include <jni.h>
#include <string>
#include "dmtx.h"

extern "C" JNIEXPORT jstring JNICALL
Java_dev_steenbakker_mobile_1scanner_DmtxNative_decodeGray(
    JNIEnv *env,
    jobject /*thiz*/,
    jbyteArray gray,
    jint width,
    jint height) {
  if (gray == nullptr || width <= 0 || height <= 0) {
    return nullptr;
  }

  jsize len = env->GetArrayLength(gray);
  jint needed = width * height;
  if (len < needed) {
    return nullptr;
  }

  jboolean isCopy = JNI_FALSE;
  jbyte *data = env->GetByteArrayElements(gray, &isCopy);
  if (data == nullptr) {
    return nullptr;
  }

  unsigned char *buffer = reinterpret_cast<unsigned char *>(data);
  DmtxImage *img = dmtxImageCreate(buffer, width, height, DmtxPack8bppK);
  if (img == nullptr) {
    env->ReleaseByteArrayElements(gray, data, JNI_ABORT);
    return nullptr;
  }

  DmtxDecode *dec = dmtxDecodeCreate(img, 1);
  if (dec == nullptr) {
    dmtxImageDestroy(&img);
    env->ReleaseByteArrayElements(gray, data, JNI_ABORT);
    return nullptr;
  }

  dmtxDecodeSetProp(dec, DmtxPropScanGap, 1);

  DmtxTime timeout = dmtxTimeAdd(dmtxTimeNow(), 80);
  DmtxRegion *reg = dmtxRegionFindNext(dec, &timeout);
  std::string result;

  if (reg != nullptr) {
    DmtxMessage *msg = dmtxDecodeMatrixRegion(dec, reg, DmtxUndefined);
    if (msg != nullptr && msg->output != nullptr && msg->outputIdx > 0) {
      result.assign(reinterpret_cast<char *>(msg->output),
                    static_cast<size_t>(msg->outputIdx));
    }
    dmtxMessageDestroy(&msg);
    dmtxRegionDestroy(&reg);
  }

  dmtxDecodeDestroy(&dec);
  dmtxImageDestroy(&img);
  env->ReleaseByteArrayElements(gray, data, JNI_ABORT);

  if (result.empty()) {
    return nullptr;
  }

  return env->NewStringUTF(result.c_str());
}
