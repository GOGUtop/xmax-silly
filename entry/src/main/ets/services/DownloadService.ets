import { webview } from '@kit.ArkWeb';
import { picker } from '@kit.CoreFileKit';
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';

export class DownloadService {
  private controller: webview.WebviewController;
  private delegate: webview.WebDownloadDelegate = new webview.WebDownloadDelegate();
  private context: common.UIAbilityContext;

  constructor(controller: webview.WebviewController, context: common.UIAbilityContext) {
    this.controller = controller;
    this.context = context;
  }

  attach(): void {
    this.delegate.onBeforeDownload((item: webview.WebDownloadItem) => {
      const fileName: string = item.getSuggestedFileName() || `sillytavern-export-${Date.now()}`;
      const saveOptions = new picker.DocumentSaveOptions();
      saveOptions.newFileNames = [fileName];
      const documentPicker = new picker.DocumentViewPicker();

      documentPicker.save(saveOptions).then((paths: string[]) => {
        if (paths.length > 0) {
          try {
            item.start(paths[0]);
            return;
          } catch (err) {
            const e = err as BusinessError;
            console.warn(`download to picker path failed: ${e.code} ${e.message}`);
          }
        }
        this.startFallback(item, fileName);
      }).catch((err: BusinessError) => {
        console.warn(`save picker cancelled/failed: ${err.code} ${err.message}`);
        this.startFallback(item, fileName);
      });
    });

    this.delegate.onDownloadUpdated((item: webview.WebDownloadItem) => {
      console.info(`download ${item.getGuid()} ${item.getPercentComplete()}%`);
    });

    this.delegate.onDownloadFailed((item: webview.WebDownloadItem) => {
      console.error(`download failed: ${item.getGuid()}`);
    });

    this.delegate.onDownloadFinish((item: webview.WebDownloadItem) => {
      console.info(`download finished: ${item.getGuid()}`);
    });

    this.controller.setDownloadDelegate(this.delegate);
  }

  private startFallback(item: webview.WebDownloadItem, fileName: string): void {
    try {
      item.start(`${this.context.cacheDir}/${fileName}`);
    } catch (err) {
      const e = err as BusinessError;
      console.error(`fallback download failed: ${e.code} ${e.message}`);
    }
  }
}
